class OrderDetail < ActiveRecord::Base
  include NUCore::Database::SortHelper
  include TranslationHelper
  include NotificationSubject
  include OrderDetail::Accessorized

  versioned

  # Used when ordering to override certain restrictions
  attr_accessor :being_purchased_by_admin

  # So you can see what price policy was used in the price estimation
  attr_reader :estimated_price_policy

  # Used to mark a dispute as resolved
  attr_accessor :resolve_dispute
  before_validation :mark_dispute_resolved, :if => :resolve_dispute
  after_validation :reset_dispute

  belongs_to :product
  belongs_to :price_policy
  belongs_to :statement, :inverse_of => :order_details
  belongs_to :journal
  belongs_to :order
  belongs_to :assigned_user, :class_name => 'User', :foreign_key => 'assigned_user_id'
  belongs_to :created_by_user, :class_name => 'User', :foreign_key => :created_by
  belongs_to :order_status
  belongs_to :account
  belongs_to :bundle, :foreign_key => 'bundle_product_id'
  has_one    :reservation, :dependent => :destroy, :inverse_of => :order_detail
  has_one    :external_service_receiver, :as => :receiver, :dependent => :destroy
  has_many   :notifications, :as => :subject, :dependent => :destroy
  has_many   :stored_files, :dependent => :destroy

  delegate :user, :facility, :ordered_at, :to => :order
  delegate :price_group, :to => :price_policy, :allow_nil => true
  def estimated_price_group
    estimated_price_policy.try(:price_group)
  end

  delegate :journal_date, :to => :journal, :allow_nil => true
  def statement_date
    statement.try(:created_at)
  end
  def journal_or_statement_date
    journal_date || statement_date
  end

  alias_method :merge!, :save!

  validates_presence_of :product_id, :order_id, :created_by
  validates_numericality_of :quantity, :only_integer => true, :greater_than_or_equal_to => 1
  validates_numericality_of :actual_cost, :greater_than_or_equal_to => 0, :if => lambda { |o| o.actual_cost_changed? && !o.actual_cost.nil?}
  validates_numericality_of :actual_subsidy, :greater_than_or_equal_to => 0, :if => lambda { |o| o.actual_subsidy_changed? && !o.actual_cost.nil?}
  validates_numericality_of :actual_total, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_presence_of :dispute_reason, :if => :dispute_at
  validates_presence_of :dispute_resolved_at, :dispute_resolved_reason, :if => Proc.new { dispute_resolved_reason.present? || dispute_resolved_at.present? }
  # only do this validation if it hasn't been ordered yet. Update errors caused by notification sending
  # were being triggered on orders where the orderer had been removed from the account.
  validate :account_usable_by_order_owner?, :if => lambda { |o| o.order.nil? or o.order.ordered_at.nil? }
  validates_length_of :note, :maximum => 100, :allow_blank => true, :allow_nil => true

  ## TODO validate assigned_user is a member of the product's facility
  ## TODO validate order status is global or a member of the product's facility
  ## TODO validate which fields can be edited for which states

  scope :with_product_type, lambda { |s| {:joins => :product, :conditions => ["products.type = ?", s.to_s.capitalize]} }
  scope :in_dispute, :conditions => ['dispute_at IS NOT NULL AND dispute_resolved_at IS NULL AND STATE != ?', 'cancelled'], :order => 'dispute_at'
  scope :new_or_inprocess, :conditions => ["order_details.state IN ('new', 'inprocess') AND orders.ordered_at IS NOT NULL"], :include => :order

  scope :facility_recent, lambda { |facility|
                                  { :conditions => ['(order_details.statement_id IS NULL OR order_details.reviewed_at > ?) AND orders.facility_id = ?', Time.zone.now, facility.id],
                                    :joins => 'LEFT JOIN statements on statements.id=statement_id INNER JOIN orders on orders.id=order_id',
                                    :order => 'order_details.created_at DESC' }}

  scope :finalized, lambda {|facility| { :joins => :order,
                                               :conditions => ['orders.facility_id = ? AND order_details.reviewed_at < ?', facility.id, Time.zone.now],
                                               :order => 'order_details.created_at DESC' }}

  def self.for_facility(facility)
    for_facility_id(facility.id)
  end

  def self.for_facility_id(facility_id=nil)
    details = joins(:order)

    unless facility_id.nil?
      details = details.where(:orders => { :facility_id => facility_id})
    end

    details
  end

  def self.for_facility_url(facility_url)
    details = scoped.joins(:order)

    unless facility_url.nil?
      details = details.joins(:order => :facility)
      details = details.where(:facilities => {:url_name => facility_url})
    end

    details
  end

  scope :for_facility_with_price_policy, lambda { |facility| {
    :joins => :order,
    :conditions => [ 'orders.facility_id = ? AND price_policy_id IS NOT NULL', facility.id ], :order => 'order_details.fulfilled_at DESC' }
  }

  scope :need_notification, lambda {{
    :joins => :product,
    :conditions => ['order_details.state = ?
                     AND order_details.reviewed_at IS NULL
                     AND order_details.price_policy_id IS NOT NULL
                     AND (dispute_at IS NULL OR dispute_resolved_at IS NOT NULL)', 'complete']
  }}

  def self.all_need_notification
    where(:state => 'complete').
    where(:reviewed_at => nil).
    where("price_policy_id IS NOT NULL").
    where("dispute_at IS NULL OR dispute_resolved_at IS NOT NULL")
  end

  scope :in_review, lambda { |facility|
    scoped.joins(:product).
    where(:products => {:facility_id => facility.id}).
    where(:state => 'complete').
    where("order_details.reviewed_at > ?", Time.zone.now).
    where("dispute_at IS NULL OR dispute_resolved_at IS NOT NULL")
  }

  def self.all_in_review
    where(:state => 'complete').
    where("order_details.reviewed_at > ?", Time.zone.now).
    where("dispute_at IS NULL OR dispute_resolved_at IS NOT NULL")
  end

  def self.recently_reviewed
    where(:state => ['complete', 'reconciled']).
    where("order_details.reviewed_at < ?", Time.zone.now).
    where("dispute_at IS NULL OR dispute_resolved_at IS NOT NULL").
    order(:reviewed_at).reverse_order
  end

  def in_review?
    # check in the database if self.id is in the scope
    self.class.all_in_review.find_by_id(self.id) ? true :false
    # this would work without hitting the database again, but duplicates the functionality of the scope
    # state == 'complete' and !reviewed_at.nil? and reviewed_at > Time.zone.now and (dispute_at.nil? or !dispute_resolved_at.nil?)
  end

  def reviewed?
    reviewed_at.present? && !in_review? && !in_dispute?
  end

  def can_be_viewed_by?(user)
    self.order.user_id == user.id || self.account.owner_user.id == user.id || self.account.business_admins.any?{|au| au.user_id == user.id}
  end

  scope :need_statement, lambda { |facility| {
    :joins => [:product, :account],
    :conditions => [
       "products.facility_id = :facility_id
       AND order_details.state = :state
       AND reviewed_at <= :reviewed_at
       AND order_details.statement_id IS NULL
       AND order_details.price_policy_id IS NOT NULL
       AND accounts.type IN (:accounts)
       AND (dispute_at IS NULL OR dispute_resolved_at IS NOT NULL)",
       { :facility_id => facility.id, :state =>'complete', :reviewed_at => Time.zone.now, :accounts => AccountManager::STATEMENT_ACCOUNT_CLASSES }
    ]
  }}

  scope :need_journal, lambda { {
    :joins => [:product, :account],
    :conditions => ['order_details.state = ?
                     AND reviewed_at <= ?
                     AND accounts.type = ?
                     AND journal_id IS NULL
                     AND order_details.price_policy_id IS NOT NULL
                     AND (dispute_at IS NULL OR dispute_resolved_at IS NOT NULL)', 'complete', Time.zone.now, 'NufsAccount']
  } }

  scope :statemented, lambda {|facility| {
      :joins => :order,
      :order => 'order_details.created_at DESC',
      :conditions => [ 'orders.facility_id = ? AND order_details.statement_id IS NOT NULL', facility.id ] }
  }

  scope :non_reservations, joins(:product).where("products.type <> 'Instrument'")
  scope :reservations, joins(:product).where("products.type = 'Instrument'")

  scope :ordered, where("orders.ordered_at IS NOT NULL")
  scope :pending, joins(:order).where(:state => ['new', 'inprocess']).ordered
  scope :confirmed_reservations,  reservations.
                                 joins(:order).
                                 includes(:reservation).
                                 ordered

  scope :upcoming_reservations, lambda { confirmed_reservations.
                                        where("reservations.reserve_end_at > ? AND reservations.actual_start_at IS NULL", Time.zone.now).
                                        order('reservations.reserve_start_at ASC')
                                      }

  scope :in_progress_reservations, confirmed_reservations.
                                  where("reservations.actual_start_at IS NOT NULL AND reservations.actual_end_at IS NULL").
                                  order('reservations.reserve_start_at ASC')

  scope :all_reservations, confirmed_reservations.
                           order('reservations.reserve_start_at DESC')

  scope :for_accounts, lambda {|accounts| where("order_details.account_id in (?)", accounts) unless accounts.nil? or accounts.empty? }
  scope :for_facilities, lambda {|facilities| joins(:order).where("orders.facility_id in (?)", facilities) unless facilities.nil? or facilities.empty? }
  scope :for_products, lambda { |products| where("order_details.product_id in (?)", products) unless products.blank? }
  scope :for_owners, lambda { |owners| joins(:account).
                                       joins("INNER JOIN account_users on account_users.account_id = accounts.id and user_role = 'Owner'").
                                       where("account_users.user_id in (?)", owners) unless owners.blank? }
  scope :for_order_statuses, lambda {|statuses| where("order_details.order_status_id in (?)", statuses) unless statuses.nil? or statuses.empty? }

  scope :in_date_range, lambda { |start_date, end_date|
    search = scoped
    if (start_date)
      search = search.where("orders.ordered_at > ?", start_date.beginning_of_day)
    end
    if (end_date)
      search = search.where("orders.ordered_at < ?", end_date.end_of_day)
    end
    search
  }

  scope :fulfilled_in_date_range, lambda {|start_date, end_date|
    action_in_date_range :fulfilled_at, start_date, end_date
  }

  scope :action_in_date_range, lambda {|action, start_date, end_date|
    valid = TransactionSearch::DATE_RANGE_FIELDS.map { |arr| arr[1].to_sym } + [:journal_date]
    raise ArgumentError.new("Invalid action: #{action}. Must be one of: #{valid}") unless valid.include? action.to_sym
    logger.debug("searching #{action} between #{start_date} and #{end_date}")
    search = scoped

    return journaled_or_statemented_in_date_range(start_date, end_date) if action.to_sym == :journal_or_statement_date
    search = search.joins(:journal) if action.to_sym == :journal_date

    # If we're searching on fulfilled_at, ignore any order details that don't have a fulfilled date
    search = search.where('fulfilled_at IS NOT NULL') if action.to_sym == :fulfilled_at

    if start_date
      search = search.where("#{action} > ?", start_date.beginning_of_day)
    end
    if end_date
      search = search.where("#{action} < ?", end_date.end_of_day)
    end
    search
  }

  def self.journaled_or_statemented_in_date_range(start_date, end_date)
    search = joins("LEFT JOIN journals ON journals.id = order_details.journal_id")
    search = search.joins("LEFT JOIN statements ON statements.id = order_details.statement_id")

    journal_query = ["journal_id IS NOT NULL"]
    journal_query << "journal_date > :start_date" if start_date
    journal_query << "journal_date < :end_date" if end_date

    statement_query = ["statement_id IS NOT NULL"]
    statement_query << "statements.created_at > :start_date" if start_date
    statement_query << "statements.created_at < :end_date" if end_date

    search = search.where("(#{journal_query.join(' AND ')}) OR (#{statement_query.join(' AND ')})", :start_date => start_date, :end_date => end_date)
    search
  end



  def self.ordered_or_reserved_in_range(start_date, end_date)
    start_date = start_date.beginning_of_day if start_date
    end_date = end_date.end_of_day if end_date

    query = joins(:order).joins('LEFT JOIN reservations ON reservations.order_detail_id = order_details.id')
    # If there is a reservation, query on the reservation time, if there's not a reservation (i.e. the left join ends up with a null reservation)
    # use the ordered at time
    if start_date && end_date
      sql = "(reservations.id IS NULL AND orders.ordered_at > :start AND orders.ordered_at < :end) OR (reservations.id IS NOT NULL AND reservations.reserve_start_at > :start AND reservations.reserve_start_at < :end)"
    elsif start_date
      sql = "(reservations.id IS NULL AND orders.ordered_at > :start) OR (reservations.id IS NOT NULL AND reservations.reserve_start_at > :start)"
    elsif end_date
      sql = "(reservations.id IS NULL AND orders.ordered_at < :end) OR (reservations.id IS NOT NULL AND reservations.reserve_start_at < :end)"
    end

    query.where(sql, {:start => start_date, :end => end_date})
  end
  # BEGIN acts_as_state_machine
  include AASM

  aasm_column           :state
  aasm_initial_state    :new
  aasm_state            :new
  aasm_state            :inprocess
  aasm_state            :complete, :enter => :make_complete
  aasm_state            :reconciled
  aasm_state            :cancelled, :enter => :clear_costs

  aasm_event :to_new do
    transitions :to => :new, :from => :inprocess
  end

  aasm_event :to_inprocess do
    transitions :to => :inprocess, :from => :new
  end

  aasm_event :to_complete do
    transitions :to => :complete, :from => [:new, :inprocess], :guard => :has_completed_reservation?
  end

  aasm_event :to_reconciled do
    transitions :to => :reconciled, :from => :complete, :guard => :actual_total
  end

  aasm_event :to_cancelled do
    transitions :to => :cancelled, :from => [:new, :inprocess, :complete], :guard => :cancelable?
  end
  # END acts_as_state_machine

  # block will be called after the transition, but before the save
  def change_status! (new_status, &block)
    new_state = new_status.state_name
    # don't try to change state if it's not a valid state or it's the same as it was before
    if OrderDetail.aasm_states.map(&:name).include?(new_state) && new_state != state.to_sym
      raise AASM::InvalidTransition, "Event '#{new_state}' cannot transition from '#{state}'" unless send("to_#{new_state}!")
    end
    # don't try to change status if it's the same as before
    unless new_status == order_status
      self.order_status = new_status
      block.call(self) if block
      self.save!
    end
    return true
  end

  # This method is a replacement for change_status! that also will cancel the associated reservation when necessary
  def update_order_status!(updated_by, order_status, options_args = {}, &block)
    options = { :admin => false, :apply_cancel_fee => false }.merge(options_args)

    if reservation && order_status.root == OrderStatus.cancelled.first
      cancel_reservation(updated_by, order_status, options[:admin], options[:apply_cancel_fee])
    else
      change_status! order_status, &block
    end
  end

  def backdate_to_complete!(event_time = Time.zone.now)
    # if we're setting it to compete, automatically set the actuals for a reservation
    if reservation
      raise NUCore::PurchaseException.new(t_model_error(Reservation, 'cannot_be_completed_in_future')) if reservation.reserve_end_at > event_time
      reservation.assign_actuals_off_reserve
      reservation.save!
    end
    change_status!(OrderStatus.complete.first) do |od|
      od.fulfilled_at = event_time
      od.assign_price_policy(event_time)
    end
  end

  def set_default_status!
    change_status! product.initial_order_status
  end

  def save_as_user(user)
    @being_purchased_by_admin = user.operator_of?(product.facility)
    save
  end

  def save_as_user!(user)
    raise ActiveRecord::RecordInvalid.new(self) unless save_as_user(user)
  end

  def cancelable?
    # can't cancel if the reservation isn't already canceled or if this OD has been added to a statement or journal
    statement.nil? && journal.nil? && (reservation.nil? || reservation.canceled_at.present?)
  end

  delegate :ordered_on_behalf_of?, :to => :order

  def cost
    actual_cost || estimated_cost
  end

  def subsidy
    actual_subsidy || estimated_subsidy
  end

  def actual_total
    if actual_cost && actual_subsidy
      actual_cost - actual_subsidy
    else
      nil
    end
  end

  def estimated_total
    if estimated_cost && estimated_subsidy
      estimated_cost - estimated_subsidy
    else
      nil
    end
  end

  def total
    unless cost.nil? || subsidy.nil?
      cost - subsidy
    else
      nil
    end
  end

  def price_groups
    groups = user.price_groups
    groups += account.price_groups if account
    groups.compact.uniq
  end

  # set the object's response_set
  def response_set!(response_set)
    self.response_set = response_set
    self.save
  end

  # returns true if the associated survey response set has been completed
  def survey_completed?
    !external_service_receiver.nil?
  end

  def account_usable_by_order_owner?
    return unless order && account_id
    errors.add("account_id", "is not valid for the orderer") unless AccountUser.find(:first, :conditions => ['user_id = ? AND account_id = ? AND deleted_at IS NULL', order.user_id, account_id])
  end

  def can_dispute?
    in_review?
  end

  def validate_for_purchase
    # can purchase product
    return "The product may not be purchased" unless product.available_for_purchase?

    # payment method is selected
    return "You must select a payment method" if account.nil?

    # payment method is not expired
    return "The account is expired and cannot be used" if account.expires_at < Time.zone.now || account.suspended_at

    # TODO if chart string, is chart string + account valid
    return "The #{account.type_string} is not open for the required account" if account.is_a?(NufsAccount) && !account.account_open?(product.account)

    # is the user approved for the product
    return "You are not approved to purchase this #{product.class.name.downcase}" unless product.can_be_used_by?(order.user) || order.created_by_user.can_override_restrictions?(product)

    # are reservation requirements met
    response = validate_reservation
    return response if response

    # are survey requirements met
    response = validate_service_meta
    return response if response

    return nil if product.can_purchase_order_detail? self

    return 'No assigned price groups allow purchase of this product'
  end

  def valid_for_purchase?
    validate_for_purchase.nil? ? true : false
  end

  def validate_reservation
    return nil unless product.is_a?(Instrument)
    return "Please make a reservation" if reservation.nil?
    reservation.reserved_by_admin = @being_purchased_by_admin
    return "There is a problem with your reservation" unless reservation.valid? && reservation.valid_before_purchase?
  end

  def valid_reservation?
    validate_reservation.nil? ? true : false
  end

  def validate_service_meta
    return nil unless product.is_a?(Service)

    requires_upload = !product.stored_files.template.empty?
    requires_survey = product.active_survey?
    valid_upload    = requires_upload ? validate_uploaded_files : nil
    valid_survey    = requires_survey ? validate_survey         : nil

    if requires_upload && requires_survey && valid_survey && valid_upload
      return "Please complete the online order form or upload an order form"
    elsif requires_upload && requires_survey && (valid_upload || valid_survey)
      return nil
    else
      return valid_upload || valid_survey
    end
  end

  def valid_service_meta?
    validate_service_meta.nil? ? true : false
  end

  def validate_uploaded_files
    templates = product.stored_files.template
    case
    when templates.empty?
      nil # no file templates
    else
      # check for a template result
      results = self.stored_files.template_result
      if results.empty?
        "Please upload an order form"
      else
        nil
      end
    end
  end

  def validate_survey
    case
    when !product.active_survey?
      nil # no active survey
    when (product.active_survey? and survey_completed?)
      nil # active survey with a completed response set
    else
      # active survey but no response
      "Please complete the online order form"
    end
  end

  def update_account(new_account)
    self.account = new_account
    assign_estimated_price(account)
  end

  def assign_estimated_price(second_account=nil, date = Time.zone.now)
    self.estimated_cost    = nil
    self.estimated_subsidy = nil
    second_account=account unless second_account

    # is account valid for facility
    return unless product.facility.can_pay_with_account?(account)


    @estimated_price_policy = product.cheapest_price_policy(self, date)
    assign_estimated_price_from_policy @estimated_price_policy
  end

  def assign_estimated_price!(second_account=nil, date = Time.zone.now)
    assign_estimated_price(second_account, date)
    self.save!
  end

  def assign_estimated_price_from_policy(price_policy)
    return unless price_policy

    costs = price_policy.estimate_cost_and_subsidy_from_order_detail(self)
    return unless costs

    self.estimated_cost    = costs[:cost]
    self.estimated_subsidy = costs[:subsidy]
  end

  def assign_price_policy(time = Time.zone.now)
    clear_costs

    # is account valid for facility
    return unless product.facility.can_pay_with_account?(account)
    assign_actual_price(time)
  end

  def assign_actual_price(time = Time.zone.now)
    pp = product.cheapest_price_policy(self, time)
    return unless pp
    costs = pp.calculate_cost_and_subsidy_from_order_detail(self)
    return unless costs
    self.price_policy_id = pp.id
    self.actual_cost     = costs[:cost]
    self.actual_subsidy  = costs[:subsidy]
    pp
  end

  def to_s
    "#{order.id}-#{id}"
  end

  def description
    "Order # #{to_s}"
  end

  def cost_estimated?
    price_policy.nil? && estimated_cost && estimated_subsidy && actual_cost.nil? && actual_subsidy.nil?
  end

  def in_dispute?
    dispute_at && dispute_resolved_at.nil? && !cancelled?
  end

  def disputed?
    dispute_at.present? && !cancelled?
  end

  def cancel_reservation(canceled_by, order_status = OrderStatus.cancelled.first, admin_cancellation = false, admin_with_cancel_fee=false)
    res = self.reservation
    res.canceled_by = canceled_by.id

    if admin_cancellation
      res.canceled_at = Time.zone.now
      return false unless res.save

      if admin_with_cancel_fee
        cancel_with_fee order_status
      else
        change_status! order_status
      end
    else
      return false unless res && res.can_cancel?
      res.canceled_at = Time.zone.now # must set canceled_at after calling #can_cancel?
      return false unless res.save
      cancel_with_fee order_status
    end
  end

  def cancellation_fee
    res    = reservation
    policy = price_policy

    unless policy
      assign_price_policy
      policy=price_policy
    end

    return 0 unless res && policy && self.product.min_cancel_hours.to_i > 0
    if (res.reserve_start_at - Time.zone.now)/3600 > self.product.min_cancel_hours
      return 0
    else
      return policy.cancellation_cost.to_f
    end
  end

  def has_subsidies?
    actual_subsidy.to_f > 0 || estimated_subsidy.to_f > 0
  end


  #
  # If this +OrderDetail+ is #complete? and either:
  #   A) Does not have a +PricePolicy+ or
  #   B) Has a reservation with missing usage information
  # the method will return true, otherwise false
  def problem_order?
    !!(complete? && (price_policy.nil? || reservation.try(:requires_but_missing_actuals?)))
  end

  def missing_price_policy?
    complete? && price_policy.nil?
  end

  def in_open_journal?
    self.journal && self.journal.open?
  end

  def can_reconcile?
    complete? && !in_dispute? && account.can_reconcile?(self)
  end

  def self.account_unreconciled(facility, account)
    if account.is_a?(NufsAccount)
      joins(:journal).for_facility(facility).where("order_details.account_id = ?  AND order_details.state = ?  AND journals.is_successful = ?",
          account.id, 'complete', true
        ).all
    else
      for_facility(facility).where("order_details.account_id = ?  AND order_details.state = ?  AND order_details.statement_id IS NOT NULL",
          account.id, 'complete'
       ).all
    end
  end

  #
  # Returns true if this order detail is part of a bundle purchase, false otherwise
  def bundled?
    !bundle.nil?
  end

  def to_notice(notification_class, *args)
    case notification_class.name
      when MergeNotification.name
        notice="<a href=\"#{facility_order_path(order.facility, order.merge_order)}\">Order ##{order.merge_order.id}</a> needs your attention. A line item was added after purchase and "

        notice += case product
          when Instrument then 'has an incomplete reservation.'
          when Service then 'has an incomplete order form.'
          else; 'is incomplete.'
        end

        notice.html_safe
      else
        ''
    end
  end

  # returns a hash of :notice (and/or?) :error
  # these should be shown to the user as an appropriate flash message
  #
  # Required Parameters:
  #
  # order_detail_ids: enumerable of strings or integers representing
  #                   order_details to attempt update of
  #
  # update_params:    a hash containing updates to attempt on the order_details
  #
  # session_user:     user requesting the update
  #
  # Acceptable Updates:
  #   key                     value
  #   ---------------------------------------------------------------------
  #   :assigned_user_id       integer or string: id of a User
  #                                              they should be assigned to
  #
  #                                               OR
  #
  #                                              'unassign'
  #                                              (to unassign current user)
  #
  #
  #   :order_status_id        integer or string: id of an OrderStatus
  #                                              they should be set to
  #
  #
  # Optional Parameters:
  #
  # msg_type:         a plural string used in error/success messages to indicate
  #                   type of records,
  #                   (since this class method is also used to update
  #                   order_details associated with reservations)
  #                   defaults to 'orders'
  def self.batch_update(order_detail_ids, current_facility, session_user, update_params, msg_type='orders')
    msg_hash = {}

    unless order_detail_ids.present?
      msg_hash[:error] = "No #{msg_type} selected"
      return msg_hash
    end
    order_details = OrderDetail.find(order_detail_ids)

    if order_details.any? { |od| od.product.facility_id != current_facility.id || !(od.state.include?('inprocess') || od.state.include?('new'))}
      msg_hash[:error] = "There was an error updating the selected #{msg_type}"
      return msg_hash
    end

    changes = false
    if update_params[:assigned_user_id] && update_params[:assigned_user_id].length > 0
      changes = true
      order_details.each {|od| od.assigned_user_id = (update_params[:assigned_user_id] == "unassign" ? nil : update_params[:assigned_user_id])}
    end

    OrderDetail.transaction do
      if update_params[:order_status_id] && update_params[:order_status_id].length > 0
        changes = true
        begin
          os = OrderStatus.find(update_params[:order_status_id])
          order_details.each do |od|
            # cancel reservation order details
            if os.id == OrderStatus.cancelled.first.id && od.reservation
              raise "#{msg_type} ##{od} failed cancellation." unless od.cancel_reservation(session_user, os, true)
            # cancel other orders or change status of any order
            else
              od.change_status!(os)
            end
          end
        rescue => e
          msg_hash[:error] = "There was an error updating the selected #{msg_type}.  #{e.message}"
          raise ActiveRecord::Rollback
        end
      end
      unless changes
        msg_hash[:notice] = "No changes were required"
        return msg_hash
      end
      begin
        order_details.all? { |od| od.save! }
        msg_hash[:notice] = "The #{msg_type} were successfully updated"
      rescue
        msg_hash[:error] = "There was an error updating the selected #{msg_type}"
        raise ActiveRecord::Rollback
      end
    end

    return msg_hash
  end

  private

  def has_completed_reservation?
    !product.is_a?(Instrument) || (reservation && (reservation.canceled_at || reservation.actual_end_at || reservation.reserve_end_at < Time.zone.now))
  end

  def make_complete
    assign_price_policy
    self.fulfilled_at=Time.zone.now
    self.reviewed_at = Time.zone.now unless SettingsHelper::has_review_period?
  end

  def cancel_with_fee(order_status)
    fee = self.cancellation_fee
    self.actual_cost = fee
    self.actual_subsidy = 0
    self.change_status!(fee > 0 ? OrderStatus.complete.first : order_status)
    self.save! if self.changed? # If the cancel goes from complete => complete, change status doesn't save
    true
  end

  def mark_dispute_resolved
    if resolve_dispute == true || resolve_dispute == '1'
      self.dispute_resolved_at = Time.zone.now
      self.reviewed_at         = Time.zone.now
    else
      resolve_dispute = '0'
    end
  end

  def clear_costs
    self.actual_cost     = nil
    self.actual_subsidy  = nil
    self.price_policy_id = nil
  end

  def reset_dispute
    if dispute_resolved_at_changed?
      if errors.any?
        self.dispute_resolved_at = dispute_resolved_at_was
        self.reviewed_at         = reviewed_at_was
      end
    end
  end

end
