class Product < ActiveRecord::Base

  include TextHelpers::Translation

  belongs_to :facility
  belongs_to :initial_order_status, class_name: "OrderStatus"
  belongs_to :facility_account
  has_many   :product_users
  has_many   :order_details
  has_many   :stored_files
  has_many   :price_groups, through: :price_group_products
  has_many   :price_group_products
  has_many :product_accessories, -> { where(deleted_at: nil) }, dependent: :destroy
  has_many   :accessories, through: :product_accessories, class_name: "Product"
  has_many   :price_policies
  has_many   :training_requests, dependent: :destroy

  validates_presence_of :name, :type
  validate_url_name :url_name, :facility_id
  validates_numericality_of(
    :account,
    only_integer: true,
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 99_999,
    if: :account_required,
  ) if SettingsHelper.feature_on? :expense_accounts

  # Use lambda so we can dynamically enable/disable in specs
  validate if: -> { SettingsHelper.feature_on?(:product_specific_contacts) } do
    errors.add(:contact_email, text("errors.models.product.attributes.contact_email.required")) unless email.present?
  end

  validate do |record|
    # Simple validation that all emails contain an @ followed by a word character,
    # and is not at the start of the string.
    unless training_request_contacts.all? { |email| email =~ /.@\w/ }
      record.errors.add(:training_request_contacts)
    end
  end

  scope :active, -> { where(is_archived: false, is_hidden: false) }
  scope :active_plus_hidden, -> { where(is_archived: false) } # TODO: phase out in favor of the .not_archived scope
  scope :alphabetized, -> { order("lower(name)") }
  scope :archived, -> { where(is_archived: true) }
  scope :not_archived, -> { where(is_archived: false) }

  def self.non_instruments
    where("products.type <> 'Instrument'")
  end

  def self.exclude(exclusion_list)
    where("products.id NOT IN (?)", exclusion_list)
  end

  def self.requiring_approval
    where(requires_approval: true)
  end

  def self.requiring_approval_by_type
    requiring_approval.group_by_type
  end

  def self.group_by_type
    order(:type, :name).group_by(&:type)
  end

  ## AR Hooks
  before_validation do
    self.requires_approval ||= false
    self.is_archived       ||= false
    self.is_hidden         ||= false

    # return true so validations will run
    true
  end
  after_create :set_default_pricing

  def initial_order_status
    self[:initial_order_status_id] ? OrderStatus.find(self[:initial_order_status_id]) : OrderStatus.default_order_status
  end

  def current_price_policies(date = Time.zone.now)
    price_policies.current_for_date(date).purchaseable
  end

  def past_price_policies
    price_policies.past
  end

  def past_price_policies_grouped_by_start_date
    past_price_policies.order("start_date DESC").group_by(&:start_date)
  end

  def upcoming_price_policies
    price_policies.upcoming
  end

  def upcoming_price_policies_grouped_by_start_date
    upcoming_price_policies.order("start_date ASC").group_by(&:start_date)
  end

  # TODO: favor the alphabetized scope over relying on Array#sort
  def <=>(obj)
    name.casecmp obj.name
  end

  # If there isn't an email specific to the product, fall back to the facility's email
  def email
    # If product_specific_contacts is off, always return the facility's email
    return facility.email unless SettingsHelper.feature_on? :product_specific_contacts
    contact_email.presence || facility.try(:email)
  end

  def description
    self[:description].html_safe if self[:description]
  end

  def parameterize
    self.class.to_s.parameterize.to_s.pluralize
  end

  def can_be_used_by?(user)
    if requires_approval?
      product_user_exists?(user)
    else
      true
    end
  end

  def to_param
    if errors[:url_name].nil?
      url_name
    else
      url_name_was
    end
  end

  def to_s
    name.presence || ""
  end

  def to_s_with_status
    to_s + (is_archived? ? " (inactive)" : "")
  end

  def set_default_pricing
    PriceGroup.globals.find_each do |pg|
      PriceGroupProduct.create!(product: self, price_group: pg)
    end
  end

  def available_for_purchase?
    !is_archived? && facility.is_active?
  end

  def can_purchase?(group_ids)
    return false unless available_for_purchase?

    # return false if there are no existing policies at all
    return false if price_policies.empty?

    # return false if there are no existing policies for the user's groups, e.g. they're a new group
    return false if price_policies.for_price_groups(group_ids).empty?

    # if there are current rules, but the user is not part of them
    if price_policies.current.any?
      return price_policies.current.for_price_groups(group_ids).where(can_purchase: true).any?
    end

    # if there are no current price policies, find the most recent price policy for each group.
    # if one of those can purchase, then allow the purchase
    group_ids.each do |group_id|
      # .try is in case the query doesn't return any values
      return true if price_policies.for_price_groups(group_id).order(:expire_date).last.try(:can_purchase?)
    end

    false
  end

  def can_purchase_order_detail?(order_detail)
    can_purchase? order_detail.price_groups.map(&:id)
  end

  def cheapest_price_policy(order_detail, date = Time.zone.now)
    groups = order_detail.price_groups
    return nil if groups.empty?
    price_policies = current_price_policies(date).to_a.delete_if { |pp| pp.restrict_purchase? || groups.exclude?(pp.price_group) }

    # provide a predictable ordering of price groups so that equal unit costs
    # are always handled the same way. Put the base group at the front of the
    # price policy array so that it takes precedence over all others that have
    # equal unit cost. See task #49823.
    base_ndx = price_policies.index { |pp| pp.price_group == PriceGroup.base.first }
    base = price_policies.delete_at base_ndx if base_ndx
    price_policies.sort! { |pp1, pp2| pp1.price_group.name <=> pp2.price_group.name }
    price_policies.unshift base if base

    price_policies.min_by do |pp|
      # default to very large number if the estimate returns a nil
      costs = pp.estimate_cost_and_subsidy_from_order_detail(order_detail) || { cost: 999_999_999, subsidy: 0 }
      costs[:cost] - costs[:subsidy]
    end
  end

  def product_type
    self.class.name.underscore.pluralize
  end

  def product_accessory_by_id(id)
    product_accessories.where(accessory_id: id).first
  end

  def has_access_list?
    respond_to?(:product_access_groups) && product_access_groups.any?
  end

  def access_group_for_user(user)
    find_product_user(user).try(:product_access_group)
  end

  def find_product_user(user)
    product_users.find_by_user_id(user.id)
  end

  def training_request_contacts
    CsvArrayString.new(self[:training_request_contacts])
  end

  def training_request_contacts=(str)
    self[:training_request_contacts] = CsvArrayString.new(str).to_s
  end

  protected

  def translation_scope
    self.class.i18n_scope
  end

  private

  def account_required
    true
  end

  def product_user_exists?(user)
    find_product_user(user).present?
  end

end
