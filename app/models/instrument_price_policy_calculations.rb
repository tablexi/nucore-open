module InstrumentPricePolicyCalculations

  def estimate_cost_and_subsidy_from_order_detail(order_detail)
    reservation = order_detail.reservation
    estimate_cost_and_subsidy reservation.reserve_start_at, reservation.reserve_end_at if reservation
  end

  def calculate_cost_and_subsidy_from_order_detail(order_detail)
    calculate_cost_and_subsidy order_detail.reservation
  end

  def estimate_cost_and_subsidy(start_at, end_at)
    return if restrict_purchase?

    return if end_at <= start_at

    return { cost: minimum_cost.to_f, subsidy: 0 } if free?

    TimeCalculator.new(self).calculate(start_at, end_at)
  end

  class TimeCalculator
    delegate :usage_rate, :usage_subsidy, :minimum_cost, :minimum_cost_subsidy, :product, to: :@policy

    def initialize(policy)
      @policy = policy
    end

    def calculate(start_at, end_at)
      duration_mins = TimeRange.new(start_at, end_at).duration_mins
      discount = calculate_discount(start_at, end_at)
      cost_and_subsidy(duration_mins, discount)
    end

    def calculate_discount(start_at, end_at)
      discount = product.schedule_rules.to_a.sum do |sr|
        sr.discount_for(start_at, end_at)
      end

      1 - (discount / 100)
    end

    def cost_and_subsidy(duration, discount)
      duration = 1 if duration <= 0

      costs = { cost: duration * usage_rate * discount }

      if costs[:cost] < minimum_cost.to_f
        { cost: minimum_cost, subsidy: minimum_cost_subsidy }
      else
        costs.merge(subsidy: duration * usage_subsidy * discount)
      end
    end

  end

  def calculate_cost_and_subsidy(reservation)
    return calculate_cancellation_costs(reservation) if reservation.canceled_at

    return { cost: minimum_cost.to_f, subsidy: 0 } if free?

    case charge_for
    when InstrumentPricePolicy::CHARGE_FOR[:reservation]
      calculate_reservation(reservation)
    when InstrumentPricePolicy::CHARGE_FOR[:usage]
      calculate_usage(reservation)
    when InstrumentPricePolicy::CHARGE_FOR[:overage]
      calculate_overage(reservation)
    end
  end

  def cancellation_penalty?(reservation)
    return false unless product.min_cancel_hours
    minutes_canceled_before = TimeRange.new(reservation.canceled_at, reservation.reserve_start_at).duration_mins
    minutes_canceled_before.minutes <= product.min_cancel_hours.hours
  end

  def calculate_discount(start_at, end_at)
    discount = product.schedule_rules.to_a.sum do |sr|
      sr.discount_for(start_at, end_at)
    end

    1 - (discount / 100)
  end

  private

  def calculate_usage(reservation)
    return unless reservation.actual_start_at && reservation.actual_end_at
    TimeCalculator.new(self).calculate(reservation.actual_start_at, reservation.actual_end_at)
  end

  def calculate_overage(reservation)
    return unless reservation.actual_start_at && reservation.actual_end_at
    end_at = [reservation.reserve_end_at, reservation.actual_end_at].max
    TimeCalculator.new(self).calculate(reservation.reserve_start_at, end_at)
  end

  def calculate_reservation(reservation)
    TimeCalculator.new(self).calculate(reservation.reserve_start_at, reservation.reserve_end_at)
  end

  def calculate_cancellation_costs(reservation)
    if cancellation_penalty?(reservation)
      { cost: cancellation_cost, subsidy: 0 }
    end
  end

end
