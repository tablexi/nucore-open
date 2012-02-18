class OrderDetail < ActiveRecord::Base
  include NUCore::Database::SortHelper
  
  versioned

  belongs_to :product
  belongs_to :price_policy
  belongs_to :statement
  belongs_to :journal
  belongs_to :order
  belongs_to :assigned_user, :class_name => 'User', :foreign_key => 'assigned_user_id'
  belongs_to :order_status
  belongs_to :account
  belongs_to :bundle, :foreign_key => 'bundle_product_id'
  has_one    :reservation, :dependent => :destroy
  has_one    :external_service_receiver, :as => :receiver, :dependent => :destroy
  has_many   :file_uploads, :dependent => :destroy

  validates_presence_of :product_id, :order_id
  validates_numericality_of :quantity, :only_integer => true, :greater_than_or_equal_to => 1
  validates_numericality_of :actual_cost, :if => lambda { |o| o.actual_cost_changed?}
  validates_numericality_of :actual_subsidy, :if => lambda { |o| o.actual_subsidy_changed?}
  validates_presence_of :dispute_reason, :if => :dispute_at
  validates_presence_of :dispute_resolved_at, :dispute_resolved_reason, :if => :dispute_resolved_reason || :dispute_resolved_at
  # only do this validation if it hasn't been ordered yet. Update errors caused by notification sending
  # were being triggered on orders where the orderer had been removed from the account.
  validate :account_usable_by_order_owner?, :if => lambda { |o| o.order.nil? or o.order.ordered_at.nil? }
  validates_length_of :note, :maximum => 25, :allow_blank => true, :allow_nil => true

  ## TODO validate assigned_user is a member of the product's facility
  ## TODO validate order status is global or a member of the product's facility
  ## TODO validate which fields can be edited for which states

  before_create :init_status

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

  scope :for_facility, lambda {|facility| { :joins => :order, :conditions => [ 'orders.facility_id = ?', facility.id ], :order => 'order_details.created_at DESC' }}

  def self.for_facility_id(facility_id)
    joins(:order).
    where(:orders => { :facility_id => facility_id})
  end
  def self.for_facility_url(facility_url)
    joins(:order).
    joins(:order => :facility).
    where(:orders => {:facilities => {:url_name => facility_url}})
  end
  
  scope :for_facility_with_price_policy, lambda { |facility| {
    :joins => :order,
    :conditions => [ 'orders.facility_id = ? AND price_policy_id IS NOT NULL', facility.id ], :order => 'order_details.fulfilled_at DESC' }
  }

  scope :need_notification, lambda { |facility| {
    :joins => :product,
    :conditions => ['products.facility_id = ?
                     AND order_details.state = ?
                     AND order_details.reviewed_at IS NULL
                     AND order_details.price_policy_id IS NOT NULL
                     AND (dispute_at IS NULL OR dispute_resolved_at IS NOT NULL)', facility.id, 'complete']
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
  def in_review?
    # check in the database if self.id is in the scope
    self.class.all_in_review.find_by_id(self.id) ? true :false
    # this would work without hitting the database again, but duplicates the functionality of the scope
    # state == 'complete' and !reviewed_at.nil? and reviewed_at > Time.zone.now and (dispute_at.nil? or !dispute_resolved_at.nil?)
  end

  scope :need_statement, lambda { |facility| {
    :joins => [:product, :account],
    :conditions => ['products.facility_id = ?
                     AND order_details.state = ?
                     AND reviewed_at <= ?
                     AND order_details.statement_id IS NULL
                     AND order_details.price_policy_id IS NOT NULL
                     AND (accounts.type = ? OR accounts.type = ?)
                     AND (dispute_at IS NULL OR dispute_resolved_at IS NOT NULL)', facility.id, 'complete', Time.zone.now, 'CreditCardAccount', 'PurchaseOrderAccount']
  }}

  scope :need_journal, lambda { |facility| {
    :joins => [:product, :account],
    :conditions => ['products.facility_id = ?
                     AND order_details.state = ?
                     AND reviewed_at <= ?
                     AND accounts.type = ?
                     AND journal_id IS NULL
                     AND order_details.price_policy_id IS NOT NULL
                     AND (dispute_at IS NULL OR dispute_resolved_at IS NOT NULL)', facility.id, 'complete', Time.zone.now, 'NufsAccount']
  }}

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
  scope :upcoming_reservations, confirmed_reservations.
                                where("reservations.reserve_end_at > ?", Time.zone.now).
                                order('reservations.reserve_start_at ASC')
  scope :all_reservations, confirmed_reservations.
                           order('reservations.reserve_start_at DESC')
  
  scope :for_accounts, lambda {|accounts| where("order_details.account_id in (?)", accounts) unless accounts.nil? or accounts.empty? }
  scope :for_facilities, lambda {|facilities| joins(:order).where("orders.facility_id in (?)", facilities) unless facilities.nil? or facilities.empty? }
  scope :for_products, lambda { |products| where("order_details.product_id in (?)", products) unless products.blank? }
  scope :for_owners, lambda { |owners| joins(:account).
                                       joins("INNER JOIN account_users on account_users.account_id = accounts.id and user_role = 'Owner'").
                                       where("account_users.user_id in (?)", owners) unless owners.blank? }
                                       
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
    logger.debug("searching #{action} between #{start_date} and #{end_date}")
    search = scoped
    if start_date
      search = search.where("#{action} > ?", start_date.beginning_of_day)
    end
    if end_date
      search = search.where("#{action} < ?", end_date.end_of_day)
    end
    search
  }
  # BEGIN acts_as_state_machine
  include AASM

  aasm_column           :state
  aasm_initial_state    :new
  aasm_state            :new
  aasm_state            :inprocess
  aasm_state            :complete, :enter => :make_complete
  aasm_state            :reconciled
  aasm_state            :cancelled

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
    transitions :to => :cancelled, :from => [:new, :inprocess], :guard => :reservation_canceled?
  end
  # END acts_as_state_machine

  def change_status! (new_status)
    success = true
    success = send("to_#{new_status.root.name.downcase.gsub(/ /,'')}!") if new_status.root.name.downcase.gsub(/ /,'') != state
    raise AASM::InvalidTransition, "Event '#{new_status.root.name.downcase.gsub(/ /,'')}' cannot transition from '#{state}'" unless success
    self.order_status = new_status
    self.save
  end

  def reservation_canceled?
    reservation.nil? || !reservation.canceled_at.nil?
  end

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
    return "The product may not be purchased" unless product.can_purchase?

    # payment method is selected
    return "You must select a payment method" if account.nil?

    # payment method is not expired
    return "The account is expired and cannot be used" if account.expires_at < Time.zone.now || account.suspended_at

    # TODO if chart string, is chart string + account valid
    return "The #{account.type_string} is not open for the required account" if account.is_a?(NufsAccount) && !account.account_open?(product.account)

    # is the user approved for the product
    return "You are not approved to purchase this #{product.class.name.downcase}" unless product.can_be_used_by?(order.user) or order.created_by_user.can_override_restrictions?(product)

    # are reservation requirements met
    response = validate_reservation
    return response unless response.nil?

    # are survey requirements met
    response = validate_service_meta
    return response unless response.nil?

    order.user.price_groups.each do |price_group|
      return nil if PriceGroupProduct.find_by_price_group_id_and_product_id(price_group.id, product.id)
    end

    return 'No assigned price groups allow purchase of this product'
  end

  def valid_for_purchase?
    validate_for_purchase.nil? ? true : false
  end

  def validate_reservation
    return nil unless product.is_a?(Instrument)
    return "Please make a reservation" if reservation.nil?
    return "There is a problem with your reservation" unless reservation.valid? && reservation.valid_before_purchase?
  end
  
  def valid_reservation?
    validate_reservation.nil? ? true : false
  end

  def validate_service_meta
    return nil unless product.is_a?(Service)

    requires_upload = !product.file_uploads.template.empty?
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
    templates = product.file_uploads.template
    case
    when templates.empty?
      nil # no file templates
    else
      # check for a template result
      results = self.file_uploads.template_result
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
    self.account_id = new_account.id
    assign_estimated_price(new_account)
  end

  def assign_estimated_price(second_account=nil)
    self.estimated_cost    = nil
    self.estimated_subsidy = nil
    second_account=account unless second_account

    # is account valid for facility
    return unless product.facility.can_pay_with_account?(account)

    policy_holder=product
    est_args=[ quantity ]

    if product.is_a?(Instrument)
      return unless reservation
      policy_holder=reservation
      est_args=[ reservation.reserve_start_at, reservation.reserve_end_at ]
    end

    pp = policy_holder.cheapest_price_policy((order.user.price_groups + second_account.price_groups).flatten.uniq)
    return unless pp
    costs = pp.estimate_cost_and_subsidy(*est_args)
    self.estimated_cost    = costs[:cost]
    self.estimated_subsidy = costs[:subsidy]
  end

  def assign_price_policy
    self.actual_cost       = nil
    self.actual_subsidy    = nil
    self.price_policy_id   = nil

    # is account valid for facility
    return unless product.facility.can_pay_with_account?(account)

    policy_holder=product
    calc_args=[ quantity ]

    if product.is_a?(Instrument)
      return unless reservation
      policy_holder=reservation
      calc_args=[ reservation ]
    end

    pgs=order.user.price_groups
    pgs += account.price_groups if account
    pp = policy_holder.cheapest_price_policy(pgs.flatten.uniq)
    return unless pp
    costs = pp.calculate_cost_and_subsidy(*calc_args)
    return unless costs
    self.price_policy_id = pp.id
    self.actual_cost     = costs[:cost]
    self.actual_subsidy  = costs[:subsidy]
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

  def cancel_reservation(canceled_by, order_status = OrderStatus.cancelled.first, admin_cancellation = false)
    res = self.reservation

    if admin_cancellation
      res.canceled_by = canceled_by.id
      res.canceled_at = Time.zone.now
      return false unless res.save
      return self.change_status!(order_status)
    else
      return false unless res && res.can_cancel?
      res.canceled_by = canceled_by.id
      res.canceled_at = Time.zone.now
      return false unless res.save

      fee = self.cancellation_fee
      # no cancelation fee
      if fee  == 0
        self.actual_subsidy = 0
        self.actual_cost    = 0
        return self.change_status!(order_status)
      # cancellation fee
      else
        self.actual_subsidy = 0
        self.actual_cost    = fee
        return self.change_status!(OrderStatus.complete.first)
      end
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
    complete? && (price_policy.nil? || reservation.try(:requires_but_missing_actuals?))
  end


  def self.account_unreconciled(facility, account)
    if account.is_a?(NufsAccount)
      find(:all,
           :joins => [:order, :journal],
           :conditions => [ 'orders.facility_id = ? AND order_details.account_id = ? AND order_details.state = ? AND journals.is_successful = ?', facility.id, account.id, 'complete', true ])
    else
      find(:all,
           :joins => :order,
           :conditions => [ 'orders.facility_id = ? AND order_details.account_id = ? AND order_details.state = ? AND order_details.statement_id IS NOT NULL', facility.id, account.id, 'complete' ])
    end
  end

  #
  # Returns true if this order detail is part of a bundle purchase, false otherwise
  def bundled?
    !bundle.nil?
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
        rescue Exception => e
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

  # initialize order detail status with product status
  def init_status
    self.order_status = product.try(:initial_order_status)
    self.state = product.initial_order_status.root.name.downcase.gsub(/ /,'')
  end

  def has_completed_reservation?
    !product.is_a?(Instrument) || (reservation && (reservation.canceled_at || reservation.actual_end_at || reservation.reserve_end_at < Time.zone.now))
  end

  def make_complete
    assign_price_policy
    self.fulfilled_at=Time.zone.now
  end

end
