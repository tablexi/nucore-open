class InstrumentPricePolicy < PricePolicy

  include InstrumentPricePolicyCalculations

  CHARGE_FOR = {
    usage: "usage",
    overage: "overage",
    reservation: "reservation",
  }.freeze

  validates :usage_rate, :minimum_cost, :usage_subsidy, :cancellation_cost, numericality: { allow_nil: true, greater_than_or_equal_to: 0 }
  validates :usage_rate, presence: true, unless: :restrict_purchase?
  validates :charge_for, inclusion: CHARGE_FOR.values
  validates :reservation_rate,
            :reservation_subsidy,
            :overage_rate,
            :overage_subsidy,
            :reservation_mins,
            :overage_mins,
            :usage_mins,
            inclusion: [nil]

  validate :subsidy_less_than_rate?, unless: :restrict_purchase?

  before_save :set_subsidy
  after_create :ensure_reservation_window

  def reservation_window
    pgp = PriceGroupProduct.find_by_price_group_id_and_product_id(price_group.id, product.id)
    pgp.try(:reservation_window) || 0
  end

  def subsidy_less_than_rate?
    if usage_subsidy && usage_rate && usage_subsidy > usage_rate
      errors.add :usage_subsidy, :subsidy_greater_than_cost
    end
  end

  def has_rate?
    usage_rate && usage_rate > -1
  end

  def has_minimum_cost?
    minimum_cost && minimum_cost > -1
  end

  def has_subsidy?
    usage_subsidy && usage_subsidy > 0
  end

  def free?
    usage_rate.to_f == 0
  end

  def usage_rate=(hourly_rate)
    super
    self[:usage_rate] /= 60.0 if self[:usage_rate].respond_to? :/
  end

  def usage_subsidy=(hourly_subsidy)
    super
    self[:usage_subsidy] /= 60.0 if self[:usage_subsidy].respond_to? :/
  end

  def hourly_usage_rate
    usage_rate.try :*, 60
  end

  def hourly_usage_subsidy
    usage_subsidy.try :*, 60
  end

  def subsidized_hourly_usage_cost
    hourly_usage_rate - hourly_usage_subsidy
  end

  def minimum_cost_subsidy
    return unless has_minimum_cost?
    minimum_cost * subsidy_ratio
  end

  def subsidized_minimum_cost
    return unless has_minimum_cost?
    minimum_cost - minimum_cost_subsidy
  end

  private

  def set_subsidy
    self.usage_subsidy ||= 0 if usage_rate
  end

  def ensure_reservation_window
    pgp = PriceGroupProduct.find_by_price_group_id_and_product_id(price_group.id, product.id)

    PriceGroupProduct.create(
      price_group: price_group,
      product: product,
      reservation_window: PriceGroupProduct::DEFAULT_RESERVATION_WINDOW,
    ) unless pgp
  end

end
