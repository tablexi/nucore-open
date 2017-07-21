class TimedServicePricePolicy < PricePolicy

  include PricePolicies::Usage

  CHARGE_FOR = { usage: "usage" }.freeze

  def estimate_cost_and_subsidy_from_order_detail(order_detail)
    return if order_detail.quantity.blank?

    estimate_cost_and_subsidy(order_detail.quantity)
  end

  def calculate_cost_and_subsidy_from_order_detail(order_detail)
    calculate_for_time(order_detail.quantity)
  end

  def estimate_cost_and_subsidy(duration)
    return if restrict_purchase?

    calculate_for_time(duration)
  end

  private

  def calculate_for_time(duration)
    start_at = Time.current.beginning_of_day
    end_at = start_at + duration.minutes
    PricePolicies::TimeBasedPriceCalculator.new(self).calculate(start_at, end_at)
  end

end
