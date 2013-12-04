class SimpleInstrumentPricePolicy < PricePolicy

  validates :usage_rate, :minimum_cost, :usage_subsidy, :cancellation_cost, numericality: { allow_nil: true, greater_than_or_equal_to: 0 }
  validates :reservation_rate, :reservation_subsidy, :overage_rate, :overage_subsidy, inclusion: [ nil ]
  validates :usage_rate, presence: true, unless: :restrict_purchase?
  validate :subsidy_less_than_rate?, unless: :restrict_purchase?

  before_save {|pp| pp.usage_subsidy ||= 0 if pp.usage_rate }

  after_create do |pp|
    # Make sure we have a default reservation window for this price group and product
    pgp = PriceGroupProduct.find_by_price_group_id_and_product_id(pp.price_group.id, pp.product.id)

    PriceGroupProduct.create(
      price_group: pp.price_group,
      product: pp.product,
      reservation_window: PriceGroupProduct::DEFAULT_RESERVATION_WINDOW
    ) unless pgp
  end


  def self.next_dates(product)
    ipps = product.price_policies
                  .where(dateize('start_date', ' > ?'), Time.zone.now)
                  .order(:start_date)
                  .select('DISTINCT(start_date) AS start_date')
                  .all

    ipps.collect{|ipp| ipp.start_date.to_date}.uniq
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


  def estimate_cost_and_subsidy_from_order_detail(order_detail)
    reservation = order_detail.reservation
    estimate_cost_and_subsidy reservation.reserve_start_at, reservation.reserve_end_at if reservation
  end


  def calculate_cost_and_subsidy_from_order_detail(order_detail)
    calculate_cost_and_subsidy order_detail.reservation
  end


  def estimate_cost_and_subsidy(start_at, end_at)
  end


  def calculate_cost_and_subsidy(reservation)
  end

end
