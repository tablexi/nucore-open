class Product < ActiveRecord::Base

  belongs_to :facility
  belongs_to :initial_order_status, :class_name => 'OrderStatus'
  belongs_to :facility_account
  has_many   :product_users
  has_many   :order_details
  has_many   :file_uploads
  has_many   :price_groups, :through => :price_group_products
  has_many   :price_group_products
  has_many   :product_accessories, :dependent => :destroy
  has_many   :accessories, :through => :product_accessories, :class_name => 'Product'
  has_many   :price_policies

  validates_presence_of :name, :type
  validate_url_name :url_name
  validates_numericality_of(
      :account,
      :only_integer => true,
      :greater_than_or_equal_to => 0,
      :less_than_or_equal_to => 99999,
      :if => :account_required
  ) if SettingsHelper.feature_on? :expense_accounts
  
  scope :active,             :conditions => { :is_archived => false, :is_hidden => false }
  scope :active_plus_hidden, :conditions => { :is_archived => false}
  scope :archived,           :conditions => { :is_archived => true }
  scope :not_archived,       :conditions => { :is_archived => false }

  
  ## AR Hooks
  before_validation do
    self.requires_approval ||= false
    self.is_archived       ||= false
    self.is_hidden         ||= false

    # return true so validations will run
    return true
  end
  after_create :set_default_pricing
  
  def initial_order_status
    self[:initial_order_status_id] ? OrderStatus.find(self[:initial_order_status_id]) : OrderStatus.default_order_status
  end

  def current_price_policies(date=Time.zone.now)
    price_policies.current_for_date(date).purchaseable
  end

  def <=> (obj)
    name.casecmp obj.name
  end

  def description
    self[:description].html_safe if self[:description]
  end
  
  def parameterize
    self.class.to_s.parameterize.to_s.pluralize
  end

  def can_be_used_by?(user)
    return true unless requires_approval?
    !(product_users.find_by_user_id(user.id).nil?)
  end

  def to_param
    if errors[:url_name].nil?
      url_name
    else
      url_name_was
    end
  end

  def to_s
    name.present? ? name.html_safe : ''
  end
  
  def to_s_with_status
    to_s + (is_archived? ? ' (inactive)' : '')
  end

  def set_default_pricing
    PriceGroup.globals.all.each do |pg|
      PriceGroupProduct.create!(:product => self, :price_group => pg)
    end
  end
  
  def is_approved_for? (user)
    return true if user.nil?
    if requires_approval?
      return requires_approval? && !product_users.find_by_user_id(user.id).nil?
    else
      true
    end
  end
  
  def available_for_purchase?
    !is_archived? && facility.is_active?
  end

  def can_purchase? (group_ids)
    return false unless available_for_purchase?

    # return false if there are no existing policies at all
    return false if price_policies.empty?
    
    # return false if there are no existing policies for the user's groups, e.g. they're a new group
    return false if price_policies.for_price_groups(group_ids).empty?

    # if there are current rules, but the user is not part of them
    if price_policies.current.any?
      return price_policies.current.for_price_groups(group_ids).where(:can_purchase => true).any? 
    end
    
    # if there are no current price policies, find the most recent price policy for each group.
    # if one of those can purchase, then allow the purchase
    group_ids.each do |group_id|
      # .try is in case the query doesn't return any values
      return true if price_policies.for_price_groups(group_id).order(:expire_date).last.try(:can_purchase?)
    end

    false
  end

  def cheapest_price_policy(order_detail, date = Time.zone.now)
    groups = groups_for_order_detail(order_detail)
    return nil if groups.empty?
    price_policies = current_price_policies(date).delete_if { |pp| pp.restrict_purchase? || groups.exclude?(pp.price_group) }
    base_ndx=price_policies.index{|pp| pp.price_group == PriceGroup.base.first}

    if base_ndx
      base=price_policies.delete_at base_ndx
      price_policies.sort!{|pp1, pp2| pp1.price_group.name <=> pp2.price_group.name}
      price_policies.unshift base
    end

    price_policies.min_by do |pp|
      # default to very large number if the estimate returns a nil
      costs = pp.estimate_cost_and_subsidy_from_order_detail(order_detail) || {:cost => 999999999, :subsidy => 0}
      costs[:cost] - costs[:subsidy]
    end
  end

  def groups_for_order_detail(order_detail)
    groups = order_detail.order.user.price_groups
    groups += order_detail.account.price_groups if order_detail.account
    groups.compact.uniq
  end

  private

  def account_required
    true
  end
  
end
