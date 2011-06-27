class Order < ActiveRecord::Base
  belongs_to :user
  belongs_to :created_by_user, :class_name => 'User', :foreign_key => :created_by
  belongs_to :account
  belongs_to :facility
  has_many   :order_details, :dependent => :destroy

  validates_presence_of :user_id, :created_by

  scope :for_user, lambda { |user| { :conditions => ['user_id = ? AND ordered_at IS NOT NULL AND state = ?', user.id, 'purchased'] } }

  # BEGIN acts_as_state_machhine
  include AASM

  aasm_column           :state
  aasm_initial_state    :new
  aasm_state            :new
  aasm_state            :validated
  aasm_state            :purchased

  aasm_event :invalidate do
    transitions :to => :new, :from => [:new, :validated]
  end

  aasm_event :validate_order do
    transitions :to => :validated, :from => [:new, :validated], :guard => :cart_valid?
  end

  aasm_event :purchase do
    transitions :to => :purchased, :from => :validated, :guard => :place_order?
  end

  aasm_event :clear do
    transitions :to => :new, :from => [:new, :validated], :guard => :clear_cart?
  end

  [ :total, :cost, :subsidy, :estimated_total, :estimated_cost, :estimated_subsidy ].each do |method_name|
    define_method(method_name) { total_cost method_name }
  end

  def cart_valid?
    has_details? && has_valid_payment? && order_details.all? {|od| od.valid_for_purchase?}
  end

  def has_valid_payment?
    order_details.all? {|od| od.account_id == account_id} && # order detail accounts match order account
    facility.can_pay_with_account?(account) &&   # payment is accepted by facility
    account.can_be_used_by?(user) &&             # user can pay with account
    account.is_active?                           # account is active/valid
  end

  def has_details?
    self.order_details.count > 0
  end

  def clear_cart?
    self.order_details.destroy_all
    self.facility = nil
    self.account = nil
    self.save
  end

  # set the ordered time and send emails
  def place_order?
    # set the ordered_at date
    self.ordered_at = DateTime.now
    self.save
#    #send email to ordering user
#    unless self.user.email.nil?
#      OrderMailer.deliver_order_receipt(self)
#    end
#
#    # send email to facility order confimation address
#    unless self.facility.order_notification_email.nil?
#      OrderMailer.deliver_facility_order_notification(self)
#    end
  end
  #####
  # END acts_as_state_machine

  def instrument_order_details
    self.order_details.find(:all, :joins => 'LEFT JOIN products p ON p.id = order_details.product_id', :conditions => { 'p.type' => 'Instrument' })
  end

  def service_order_details
    self.order_details.find(:all, :joins => 'LEFT JOIN products p ON p.id = order_details.product_id', :conditions => { 'p.type' => 'Service' })
  end

  def item_order_details
    self.order_details.find(:all, :joins => 'LEFT JOIN products p ON p.id = order_details.product_id', :conditions => { 'p.type' => 'Item' })
  end

  def add(product, quantity=1)
    if self.facility && product.facility != self.facility && self.order_details.length > 0
      raise NUCore::MixedFacilityCart
    end

    case product
      when Bundle
        ods = []
        group_id = max_group_id + 1
        product.bundle_products.each do |bp|
          order_detail = order_details.create(:product_id => bp.product.id, :quantity => bp.quantity, :bundle_product_id => product.id, :group_id => group_id)
          order_detail.update_account(account)
          order_detail.save!
          ods << order_detail
        end
        self.facility = product.facility
        save!
        return ods
      when Item
        order_detail = self.order_details.first(:conditions => ['product_id = ? AND group_id IS NULL', product.id])
        if order_detail.nil?
          order_detail = order_details.create(:product_id => product.id, :quantity => 1)
        else
          order_detail.quantity += quantity.to_i
        end
        order_detail.update_account(account)
      else
        order_detail = order_details.create(:product_id => product.id, :quantity => 1)
        order_detail.update_account(account)
    end
    self.facility = product.facility
    save!
    order_detail.save!
    return order_detail
  end

  def update_quantities(order_detail_quantities)
    order_details = self.order_details.find(order_detail_quantities.keys)
    order_details.each do |order_detail|
      quantity = order_detail_quantities[order_detail.id]
      if quantity > 0
        order_detail.quantity = quantity
        order_detail.assign_estimated_price if order_detail.cost_estimated?
        order_detail.save
      else
        order_detail.destroy
      end
    end
  end
  
  def max_group_id
    od = self.order_details.find(:first, :select => 'MAX(group_id) AS max_group_id', :group => 'order_details.order_id')
    od.nil? ? 0 : od.max_group_id.to_i
  end

  def has_subsidies?
    order_details.any?{|od| od.has_subsidies?}
  end


  private

  def total_cost(order_detail_method)
    cost = 0
    order_details.each { |od|
      od_cost=od.method(order_detail_method.to_sym).call
      cost += od_cost if od_cost
    }
    cost
  end
end
