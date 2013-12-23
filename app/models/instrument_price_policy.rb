class InstrumentPricePolicy < PricePolicy
  include InstrumentPricePolicyCalculations

  CHARGE_FOR = {
    usage: 1,
    overage: 2,
    reservation: 3
  }

  validates :usage_rate, :minimum_cost, :usage_subsidy, :cancellation_cost, numericality: { allow_nil: true, greater_than_or_equal_to: 0 }
  validates :usage_rate, presence: true, unless: :restrict_purchase?
  validates :charge_for, inclusion: CHARGE_FOR.values
  validates :reservation_rate,
            :reservation_subsidy,
            :overage_rate,
            :overage_subsidy,
            :reservation_mins,
            :overage_mins,
            inclusion: [ nil ]

  validate :subsidy_less_than_rate?, unless: :restrict_purchase?


  before_save :set_subsidy, :set_usage_mins

  after_create do |pp|
    # Make sure we have a default reservation window for this price group and product
    pgp = PriceGroupProduct.find_by_price_group_id_and_product_id(pp.price_group.id, pp.product.id)

    PriceGroupProduct.create(
      price_group: pp.price_group,
      product: pp.product,
      reservation_window: PriceGroupProduct::DEFAULT_RESERVATION_WINDOW
    ) unless pgp
  end


  def reservation_window
    pgp = PriceGroupProduct.find_by_price_group_id_and_product_id(price_group.id, product.id)
    pgp.try(:reservation_window) || 0
  end


  def subsidy_less_than_rate?
    if usage_subsidy && usage_rate && usage_subsidy > usage_rate
      errors.add("usage_subsidy", "cannot be greater than the Usage cost")
    end
  end


  def has_subsidy?
    usage_subsidy && usage_subsidy > 0
  end


  def free?
    usage_rate.to_f == 0
  end


  private

  def set_subsidy
    self.usage_subsidy ||= 0 if usage_rate
  end


  def set_usage_mins
    self.usage_mins = 60
  end
end
