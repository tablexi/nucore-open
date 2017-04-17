class InstrumentPricePolicy < PricePolicy

  include InstrumentPricePolicyCalculations
  include PricePolicies::Usage

  CHARGE_FOR = {
    usage: "usage",
    overage: "overage",
    reservation: "reservation",
  }.freeze

  validates :cancellation_cost, numericality: { allow_blank: true, greater_than_or_equal_to: 0 }
  validates :charge_for, inclusion: CHARGE_FOR.values

  # Deprecated attributes used by OldPricePolicy
  validates :reservation_rate,
            :reservation_subsidy,
            :overage_rate,
            :overage_subsidy,
            :reservation_mins,
            :overage_mins,
            :usage_mins,
            inclusion: [nil]

  after_create :ensure_reservation_window

  def reservation_window
    pgp = PriceGroupProduct.find_by_price_group_id_and_product_id(price_group.id, product.id)
    pgp.try(:reservation_window) || 0
  end

  private

  def ensure_reservation_window
    pgp = PriceGroupProduct.find_by_price_group_id_and_product_id(price_group.id, product.id)

    PriceGroupProduct.create(
      price_group: price_group,
      product: product,
      reservation_window: PriceGroupProduct::DEFAULT_RESERVATION_WINDOW,
    ) unless pgp
  end

end
