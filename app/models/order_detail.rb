class OrderDetail < ActiveRecord::Base
  versioned

  belongs_to :product
  belongs_to :price_policy
  belongs_to :order
  belongs_to :assigned_user, :class_name => 'User', :foreign_key => 'assigned_user_id'
  belongs_to :order_status
  belongs_to :account
  belongs_to :bundle, :foreign_key => 'bundle_product_id'
  has_many   :credit_account_transactions
  has_many   :purchase_account_transactions
  has_many   :account_transactions
  has_one    :reservation, :dependent => :destroy
  belongs_to :response_set, :dependent => :destroy
  has_many   :file_uploads, :dependent => :destroy

  validates_presence_of :product_id, :order_id
  validates_numericality_of :quantity, :only_integer => true, :greater_than_or_equal_to => 1
  validates_numericality_of :actual_cost, :if => lambda { |o| o.actual_cost_changed?}
  validates_numericality_of :actual_subsidy, :if => lambda { |o| o.actual_subsidy_changed?}
  validates_presence_of :dispute_reason, :if => :dispute_at
  validates_presence_of :dispute_resolved_at, :dispute_resolved_reason, :if => :dispute_resolved_reason || :dispute_resolved_credit || :dispute_resolved_at
  validates_numericality_of :dispute_resolved_credit, :greater_than => 0, :allow_nil => true
  validate :credit_less_than_cost?, :if => :dispute_resolved_credit
  validate :account_usable_by_order_owner?
  validates_length_of :note, :maximum => 25, :allow_blank => true, :allow_nil => true

  ## TODO validate assigned_user is a member of the product's facility
  ## TODO validate order status is global or a member of the product's facility
  ## TODO validate which fields can be edited for which states

  before_create :init_status

  named_scope :with_product_type, lambda { |s| {:joins => :product, :conditions => ["products.type = ?", s.to_s.capitalize]} }
  named_scope :in_dispute, :conditions => ['dispute_at IS NOT NULL AND dispute_resolved_at IS NULL AND STATE != ?', 'cancelled'], :order => 'dispute_at'
  named_scope :new_or_inprocess, :conditions => ["order_details.state IN ('new', 'inprocess') AND orders.ordered_at IS NOT NULL"], :include => :order, :order => 'orders.ordered_at DESC'

  # BEGIN acts_as_state_machine
  include AASM

  aasm_column           :state
  aasm_initial_state    :new
  aasm_state            :new
  aasm_state            :inprocess
  aasm_state            :reviewable
  aasm_state            :complete
  aasm_state            :cancelled

  aasm_event :to_new do
    transitions :to => :new, :from => [:reviewable, :inprocess]
  end

  aasm_event :to_inprocess do
    transitions :to => :inprocess, :from => [:new, :reviewable]
  end

  aasm_event :to_reviewable do
    transitions :to => :reviewable, :from => [:new, :inprocess], :guard => :reservation_over?
  end

  aasm_event :to_complete do
    transitions :to => :complete, :from => [:reviewable], :guard => :has_purchase_account_transaction?
  end

  aasm_event :to_cancelled do
    transitions :to => :cancelled, :from => [:new, :inprocess, :reviewable], :guard => :reservation_canceled?
  end
  # END acts_as_state_machine

  def change_status! (new_status)
    success = true
    success = send("to_#{new_status.root.name.downcase.gsub(/ /,'')}!") if new_status.root.name.downcase.gsub(/ /,'') != state
    raise AASM::InvalidTransition, "Event '#{new_status.root.name.downcase.gsub(/ /,'')}' cannot transition from '#{state}'" unless success
    self.order_status = new_status
    self.save
  end

  def reservation_over?
    if !product.is_a?(Instrument) || reservation.actual_end_at || reservation.reserve_end_at < Time.zone.now
      true
    else
      false
    end
  end

  def has_purchase_account_transaction?
    !purchase_account_transactions.empty?
  end

  def reservation_canceled?
    reservation.nil? || !reservation.canceled_at.nil?
  end

  def init_purchase_account_transaction
    PurchaseAccountTransaction.new({:account_id => account_id, :facility_id => product.facility_id, :description => "Order # #{self.to_s}", :transaction_amount => (actual_total - dispute_resolved_credit.to_f), :order_detail_id => id, :is_in_dispute => false})
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
    # default to false if there is no response_set
    return false if self.response_set.blank?
    # check response_set completed_at timestamp
    !self.response_set.completed_at.blank?
  end

  def account_usable_by_order_owner?
    return unless order && account_id
    errors.add("account_id", "is not valid for the orderer") unless AccountUser.find(:first, :conditions => ['user_id = ? AND account_id = ? AND deleted_at IS NULL', order.user_id, account_id])
  end

  def credit_less_than_cost?
    errors.add("dispute_resolved_credit", "must not be greater than the total of the order detail") if dispute_resolved_credit > actual_total
  end

  def can_dispute?
    return false unless self.complete?
    pending_transaction = purchase_account_transactions.find(:first,
          :conditions => ['(finalized_at > ? OR finalized_at IS NULL) AND account_transactions.account_id = ?', Time.zone.now, self.account.id])
    if pending_transaction && dispute_at.nil?
      true
    else
      false
    end
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
    return "You are not approved to purchase this #{product.class.name.downcase}" unless product.can_be_used_by?(order.user)

    # are reservation requirements met
    response = validate_reservation
    return response unless response.nil?

    # are survey requirements met
    response = validate_service_meta
    return response unless response.nil?

    # is there an actual price / estimated price (checks to make sure there is a valid price group/price policy)
    return "A price cannot be determined using the payment method selected" unless price_policy_id && ((estimated_cost && estimated_subsidy) || (actual_cost && actual_subsidy))

    # is the user still a member of the appropriate price group and getting the best price?
    if product.is_a?(Instrument)
      pp = reservation.cheapest_price_policy((order.user.price_groups + account.price_groups).flatten.uniq)
    else
      pp = product.cheapest_price_policy((order.user.price_groups + account.price_groups).flatten.uniq)
    end
    return "PRICE GROUP / POLICY ERROR" if pp.nil? || pp.id != price_policy_id
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
    # set account id
    self.account_id        = new_account.id
    self.estimated_cost    = nil
    self.estimated_subsidy = nil
    self.actual_cost       = nil
    self.actual_subsidy    = nil
    self.price_policy_id   = nil

    # is account valid for facility
    return unless product.facility.can_pay_with_account?(account)

    # is reservation valid
    if product.is_a?(Instrument)
      if !reservation.nil?
        pp = reservation.cheapest_price_policy((order.user.price_groups + new_account.price_groups).flatten.uniq)
        return unless pp
        costs = pp.estimate_cost_and_subsidy(reservation.reserve_start_at, reservation.reserve_end_at)
        self.price_policy_id   = pp.id
        self.estimated_cost    = costs[:cost]
        self.estimated_subsidy = costs[:subsidy]
      end
      return
    end

    # set cost and subsidy for items and services
    pp = product.cheapest_price_policy((order.user.price_groups + new_account.price_groups).flatten.uniq)
    return unless pp
    costs = pp.calculate_cost_and_subsidy(quantity)
    self.price_policy_id = pp.id
    self.actual_cost     = costs[:cost]
    self.actual_subsidy  = costs[:subsidy]
  end

  def to_s
    "#{order.id}-#{id}"
  end

  def in_dispute?
    dispute_resolved_at.nil? && !dispute_at.nil?
  end

  def current_purchase_account_transaction
    purchase_account_transactions.find(:first, :conditions => {:account_id => account_id}, :order => 'created_at DESC')
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
      if cancellation_fee  == 0
        self.actual_subsidy = 0
        self.actual_cost    = 0
        return self.change_status!(order_status)
      # cancellation fee
      else
        self.actual_subsidy = 0
        self.actual_cost    = fee
        return self.change_status!(OrderStatus.reviewable.first)
      end
    end
  end

  def cancellation_fee
    res    = reservation
    policy = price_policy
    return 0 unless res && policy && self.product.min_cancel_hours.to_i > 0
    if (res.reserve_start_at - Time.zone.now)/(60*60) > self.product.min_cancel_hours
      return 0
    else
      return policy.cancellation_cost.to_f
    end
  end

  def has_subsidies?
    actual_subsidy.to_f > 0 || estimated_subsidy.to_f > 0
  end

  protected

  # initialize order detail status with product status
  def init_status
    self.order_status = product.try(:initial_order_status)
    self.state = product.initial_order_status.root.name.downcase.gsub(/ /,'')
  end

end
