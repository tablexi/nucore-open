module InstrumentPricePolicyCalculations

  def estimate_cost_and_subsidy_from_order_detail(order_detail)
    reservation = order_detail.reservation
    estimate_cost_and_subsidy reservation.reserve_start_at, reservation.reserve_end_at if reservation
  end


  def estimate_cost_and_subsidy(start_at, end_at)
    start_at = strip_seconds start_at
    end_at = strip_seconds end_at
    return nil if restrict_purchase? || end_at <= start_at

    return { cost: minimum_cost || 0, subsidy: 0 } if free?

    duration = (end_at - start_at) / 60
    discount = calculate_discount start_at, end_at
    factor_minimum cost_and_subsidy(duration, discount)
  end


  def calculate_cost(duration_mins, discount)
    duration_mins * usage_rate * discount
  end


  def calculate_subsidy(duration_mins, discount)
    duration_mins * usage_subsidy * discount
  end


  def calculate_discount(start_at, end_at)
    discount = 0

    product.schedule_rules.each do |sr|
      discount += sr.discount_for(start_at, end_at)
    end

    1 - discount / 100
  end


  def calculate_cost_and_subsidy_from_order_detail(order_detail)
    calculate_cost_and_subsidy order_detail.reservation
  end


  def calculate_cost_and_subsidy(reservation)
    return calculate_cancellation_costs(reservation) if reservation.canceled_at

    return { cost: minimum_cost || 0, subsidy: 0 } if free?

    return calculate_reservation(reservation) if charge_for == InstrumentPricePolicy::CHARGE_FOR[:reservation]

    return nil unless reservation.actual_start_at && reservation.actual_end_at

    case charge_for
      when InstrumentPricePolicy::CHARGE_FOR[:usage]
        calculate_usage(reservation)
      when InstrumentPricePolicy::CHARGE_FOR[:overage]
        calculate_overage(reservation)
    end
  end


  def cancellation_penalty?(reservation)
    return false unless product.min_cancel_hours
    res_start_at = strip_seconds reservation.reserve_start_at
    cancelled_at = strip_seconds reservation.canceled_at
    res_start_at - cancelled_at <= product.min_cancel_hours.hours
  end


  def calculate_cancellation_costs(reservation)
    cancellation_penalty?(reservation) ? { :cost => cancellation_cost, :subsidy => 0 } : nil
  end


  def calculate_usage(reservation)
    act_end_at = strip_seconds reservation.actual_end_at
    act_start_at = strip_seconds reservation.actual_start_at
    factor_minimum cost_and_subsidy_from(act_start_at, act_end_at)
  end


  #
  # for a good explanation of overage see http://pm.tablexi.com/issues/79737#note-5
  def calculate_overage(reservation)
    reservation_costs = calculate_reservation reservation
    usage_end = strip_seconds reservation.actual_end_at
    reserve_end = strip_seconds reservation.reserve_end_at
    return reservation_costs if usage_end <= reserve_end

    overage_costs = cost_and_subsidy_from reserve_end, usage_end
    factor_minimum  sum_costs(reservation_costs, overage_costs)
  end


  def calculate_reservation(reservation)
    estimate_cost_and_subsidy reservation.reserve_start_at, reservation.reserve_end_at
  end


  private

  def cost_and_subsidy(duration, discount)
    duration = 1 if duration <= 0
    costs = {}
    costs[:cost] = calculate_cost duration, discount
    costs[:subsidy] = calculate_subsidy duration, discount
    costs
  end


  def factor_minimum(costs)
    return costs unless apply_minimum? costs
    costs[:cost] = minimum_cost
    costs[:subsidy] = 0
    costs
  end


  def apply_minimum?(costs)
    costs && ((costs[:cost] - costs[:subsidy]) < minimum_cost.to_f)
  end


  def cost_and_subsidy_from(start_at, end_at)
    usage_minutes = (end_at - start_at) / 60
    discount = calculate_discount start_at, end_at
    cost_and_subsidy usage_minutes, discount
  end


  def sum_costs(cost1, cost2)
    return nil unless cost1 && cost2

    price = {}
    price[:cost] = cost1[:cost] + cost2[:cost]
    price[:subsidy] = cost1[:subsidy] + cost2[:subsidy]
    price
  end


  def strip_seconds(datetime)
    datetime.change sec: 0
  end
end
