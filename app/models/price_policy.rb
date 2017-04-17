class PricePolicy < ActiveRecord::Base

  include NUCore::Database::DateHelper

  belongs_to :price_group
  belongs_to :product
  has_many :order_details

  validates_presence_of :start_date, :price_group_id, :type
  validate :start_date_is_unique, if: :start_date?

  validate :subsidy_less_than_rate, unless: :restrict_purchase?

  validates_each :expire_date do |record, _attr, value|
    unless value.blank?
      start_date = record.start_date
      gen_exp_date = generate_expire_date(start_date)
      if value <= start_date || value > gen_exp_date
        record.errors.add(:expire_date, "must be after #{start_date.to_date} and before #{gen_exp_date.to_date}")
      end
    end
  end

  before_save :set_default_subsidy
  before_create :set_expire_date
  before_create :truncate_existing_policies

  def self.for_date(start_date)
    where("start_date >= ? AND start_date <= ?", start_date.beginning_of_day, start_date.end_of_day)
  end

  def self.current
    current_for_date(Time.zone.now)
  end

  def self.current_and_newest
    # TODO: Fix bug that allows overlapping price policies (in truncate_existing_policies)
    # This method returns the newest price policy for when price policies accidentally overlap.
    current.newest
  end

  def self.newest
    ids = group(:price_group_id).maximum(:id).values
    where(id: ids)
  end

  def self.current_for_date(date)
    where("start_date <= :now AND expire_date > :now", now: date)
  end

  def self.purchaseable
    where(can_purchase: true)
  end

  def self.upcoming
    where("start_date > :now", now: Time.zone.now)
  end

  def self.past
    where("expire_date < :now", now: Time.zone.now)
  end

  def self.for_price_groups(price_groups)
    where(price_group_id: price_groups)
  end

  def self.current_date(product)
    now = Time.current
    product
      .price_policies
      .where("start_date <= ?", now)
      .where("expire_date > ?", now)
      .order(start_date: :desc)
      .pluck(:start_date)
      .first
      .try(:to_date)
  end

  def self.next_date(product)
    product
      .price_policies
      .where("start_date > ?", Time.current)
      .order(:start_date)
      .pluck(:start_date)
      .first
      .try(:to_date)
  end

  def self.next_dates(product)
    product.price_policies
           .where("start_date > ?", Time.zone.now.beginning_of_day)
           .order(:start_date)
           .uniq
           .pluck(:start_date)
           .map &:to_date
  end

  #
  # Given a +PricePolicy+ or +Date+ determine the next
  # appropriate expiration date.
  def self.generate_expire_date(price_policy_or_date)
    start_date = price_policy_or_date.is_a?(PricePolicy) ? price_policy_or_date.start_date : price_policy_or_date
    SettingsHelper.fiscal_year_end(start_date)
  end

  def has_subsidy?
    self[subsidy_field].to_f > 0
  end

  def product_type
    self.class.name.gsub("PricePolicy", "").downcase
  end

  #
  # A price estimate for a +Product+.
  # Must return { :cost => estimated_cost, :subsidy => estimated_subsidy }
  def estimate_cost_and_subsidy(*_args)
    raise "subclass must implement!"
  end

  #
  # Same as #estimate_cost_and_subsidy, but with actual prices
  def calculate_cost_and_subsidy(*_args)
    raise "subclass must implement!"
  end

  #
  # Returns true if this PricePolicy's +Product+ cannot be purchased
  # by this PricePolicy's +PriceGroup+, false otherwise.
  def restrict_purchase
    return false unless price_group && product
    !can_purchase?
  end

  alias restrict_purchase? restrict_purchase

  #
  # Dis/allows the purchase of this PricePolicy's +Product+ by this
  # PricePolicy's +PriceGroup+.
  # [_state_]
  #   true or 1 if #product should not be purchaseable by #price_group
  #   false or 0 if #product should be purchaseable by #price_group
  def restrict_purchase=(state)
    case state
    when false, 0
      self.can_purchase = true
    when true, 1
      self.can_purchase = false
    else
      raise ArgumentError.new("state must be true, false, 0, or 1")
    end
  end

  #
  # Returns true if this +PricePolicy+ is assigned
  # to any order, false otherwise
  def assigned_to_order?
    OrderDetail.where(price_policy_id: id).any?
  end

  #
  # Returns true if #expire_date is prior to or the same
  # as today's date, false otherwise
  def expired?
    expire_date <= Time.zone.now
  end

  def editable?
    !expired? && !assigned_to_order?
  end

  private

  def set_expire_date
    self.expire_date ||= self.class.generate_expire_date(self)
  end

  def start_date_is_unique # TODO: Refactor
    type          = self.class.name.downcase.gsub(/pricepolicy$/, "")
    price_group   = self.price_group
    unless product.nil? || price_group.nil?
      if id.nil?
        pp = PricePolicy.find_by(price_group_id: price_group.id, product_id: product.id, start_date: start_date)
      else
        pp = PricePolicy.where(price_group_id: price_group.id, product_id: product.id, start_date: start_date).where.not(id: id).first
      end
      errors.add("start_date", "conflicts with an existing price rule") unless pp.nil?
    end
  end

  def set_default_subsidy
    self[subsidy_field] ||= 0 if self[rate_field]
  end

  def subsidy_less_than_rate
    return unless defined?(rate_field)
    if self[rate_field] && self[subsidy_field] && self[subsidy_field] > self[rate_field]
      errors.add subsidy_field, :subsidy_greater_than_cost
    end
  end

  def truncate_existing_policies
    logger.debug("Truncating existing policies")
    existing_policies = PricePolicy.current.where(type: self.class.name,
                                                  price_group_id: price_group_id,
                                                  product_id: product_id)

    existing_policies = existing_policies.where("id != ?", id) unless id.nil?

    existing_policies.each do |policy|
      policy.expire_date = (start_date - 1.day).end_of_day
      policy.save
    end
  end


end
