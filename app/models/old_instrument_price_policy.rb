class OldInstrumentPricePolicy < PricePolicy
  include OldInstrumentPricePolicyCalculations

  @@intervals = [1, 5, 10, 15, 30, 60]

  validates_numericality_of :minimum_cost, :usage_rate, :reservation_rate, :overage_rate, :usage_subsidy, :overage_subsidy, :reservation_subsidy, :cancellation_cost, allow_nil: true, greater_than_or_equal_to: 0
  validates_inclusion_of :usage_mins, :reservation_mins, :overage_mins, :in => @@intervals, :unless => :restrict_purchase
  validates_presence_of :usage_rate, :unless => lambda { |o| o.reservation_rate || o.usage_subsidy.nil? || o.restrict_purchase?}
  validates_presence_of :reservation_rate, :unless => lambda { |o| o.usage_rate || o.reservation_subsidy.nil? || o.restrict_purchase?}
  validate :has_usage_or_reservation_rate?, :unless => :restrict_purchase
  validate :subsidy_less_than_rate?, :unless => :restrict_purchase

  before_save do |o|
    o.usage_subsidy       = 0 if o.usage_subsidy.nil?       && !o.usage_rate.nil?
    o.reservation_subsidy = 0 if o.reservation_subsidy.nil? && !o.reservation_rate.nil?
    o.overage_subsidy     = 0 if o.overage_subsidy.nil?     && !o.overage_rate.nil?
  end

  # Make sure we have a default reservation window for this price group and product
  after_create do |o|
    pgp=PriceGroupProduct.find_by_price_group_id_and_product_id(o.price_group.id, o.product.id)
    PriceGroupProduct.create(:price_group => o.price_group, :product => o.product, :reservation_window => PriceGroupProduct::DEFAULT_RESERVATION_WINDOW) unless pgp
  end


  def self.intervals
    @@intervals
  end


  def has_usage_or_reservation_rate?
    errors.add(:base, "You must enter a reservation rate or usage rate for all price groups") if usage_rate.nil? && reservation_rate.nil?
  end


  def reservation_window
    pgp=PriceGroupProduct.find_by_price_group_id_and_product_id(price_group.id, product.id)
    return pgp ? pgp.reservation_window : 0
  end


  def subsidy_less_than_rate?
    if (reservation_subsidy && reservation_rate)
      errors.add("reservation_subsidy", "cannot be greater than the Reservation cost") if (reservation_subsidy > reservation_rate)
    end
    if (usage_subsidy && usage_rate)
      errors.add("usage_subsidy", "cannot be greater than the Usage cost") if (usage_subsidy > usage_rate)
    end
    if (overage_subsidy && overage_rate)
      errors.add("overage_subsidy", "cannot be greater than the Overage cost") if (overage_subsidy > overage_rate)
    end
  end


  # if the subsidy is zero, return false
  def has_subsidy?
    usage_subsidy && usage_subsidy > 0
  end


  def free?
    @is_free ||= (reservation_rate.to_f == 0 && usage_rate.to_f == 0 && overage_rate.to_f == 0)
  end
end
