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
            :usage_mins,
            inclusion: [ nil ]

  validate :subsidy_less_than_rate?, unless: :restrict_purchase?

  before_save :set_subsidy

  after_create {|pp| ensure_reservation_window(pp) }


  def reservation_window
    pgp = PriceGroupProduct.find_by_price_group_id_and_product_id(price_group.id, product.id)
    pgp.try(:reservation_window) || 0
  end


  def subsidy_less_than_rate?
    if usage_subsidy && usage_rate && usage_subsidy > usage_rate
      errors.add :usage_subsidy, I18n.t('activerecord.errors.models.instrument_price_policy.usage_subsidy')
    end
  end


  def has_subsidy?
    usage_subsidy && usage_subsidy > 0
  end


  def free?
    usage_rate.to_f == 0
  end


  def rate_per_minute
    usage_rate.to_f / 60
  end


  def subsidy_per_minute
    usage_subsidy.to_f / 60
  end


  private

  def set_subsidy
    self.usage_subsidy ||= 0 if usage_rate
  end


  def ensure_reservation_window(price_policy)
    pgp = PriceGroupProduct.find_by_price_group_id_and_product_id(price_policy.price_group.id, price_policy.product.id)

    PriceGroupProduct.create(
      price_group: price_policy.price_group,
      product: price_policy.product,
      reservation_window: PriceGroupProduct::DEFAULT_RESERVATION_WINDOW
    ) unless pgp
  end
end
