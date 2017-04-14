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

    return { cost: minimum_cost || 0, subsidy: 0 } if free?

    calculate_for_time(start_at, end_at)
  end

  def calculate_cost_and_subsidy(reservation)
    return calculate_cancellation_costs(reservation) if reservation.canceled_at

    return { cost: minimum_cost || 0, subsidy: 0 } if free?

    case charge_for
    when InstrumentPricePolicy::CHARGE_FOR[:reservation]
      calculate_reservation(reservation)
    when InstrumentPricePolicy::CHARGE_FOR[:usage]
      calculate_usage(reservation)
    when InstrumentPricePolicy::CHARGE_FOR[:overage]
      calculate_overage(reservation)
    end
  end

  def calculate_usage(reservation)
    return unless reservation.actual_start_at && reservation.actual_end_at
    calculate_for_time(reservation.actual_start_at, reservation.actual_end_at)
  end

  def calculate_overage(reservation)
    return unless reservation.actual_start_at && reservation.actual_end_at
    end_at = [reservation.reserve_end_at, reservation.actual_end_at].max
    calculate_for_time(reservation.reserve_start_at, end_at)
  end

  def calculate_reservation(reservation)
    calculate_for_time(reservation.reserve_start_at, reservation.reserve_end_at)
  end

  def cancellation_penalty?(reservation)
    return false unless product.min_cancel_hours
    res_start_at = strip_seconds reservation.reserve_start_at
    canceled_at = strip_seconds reservation.canceled_at
    res_start_at - canceled_at <= product.min_cancel_hours.hours
  end

  def calculate_cancellation_costs(reservation)
    if cancellation_penalty?(reservation)
      { cost: cancellation_cost, subsidy: 0 }
    end
  end

  def calculate_cost(duration_mins, discount)
    duration_mins * usage_rate * discount
  end

  def calculate_subsidy(duration_mins, discount)
    duration_mins * usage_subsidy * discount
  end

  def calculate_discount(start_at, end_at)
    discount = product.schedule_rules.to_a.sum do |sr|
      sr.discount_for(start_at, end_at)
    end

    1 - (discount / 100)
  end

  private

  def calculate_for_time(start_at, end_at)
    duration = strip_seconds(end_at) - strip_seconds(start_at)
    duration_mins = duration / 60
    discount = calculate_discount(start_at, end_at)
    cost_and_subsidy(duration_mins, discount)
  end

  def cost_and_subsidy(duration, discount)
    duration = 1 if duration <= 0

    costs = { cost: calculate_cost(duration, discount) }

    if costs[:cost] < minimum_cost.to_f
      costs[:cost] = minimum_cost
      costs[:subsidy] = calculate_subsidy_for_cost minimum_cost
    else
      costs[:subsidy] = calculate_subsidy duration, discount
    end

    costs
  end

  def calculate_subsidy_for_cost(cost)
    usage_subsidy.present? ? (cost * usage_subsidy / usage_rate) : 0
  end

  def strip_seconds(datetime)
    datetime.change sec: 0
  end

end
