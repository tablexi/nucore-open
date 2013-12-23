module InstrumentPricePolicyCalculations

  def estimate_cost_and_subsidy_from_order_detail(order_detail)
    reservation = order_detail.reservation
    estimate_cost_and_subsidy reservation.reserve_start_at, reservation.reserve_end_at if reservation
  end


  def estimate_cost_and_subsidy(start_at, end_at)
    return nil if restrict_purchase? || end_at <= start_at

    costs = {}

    if free?
      costs[:cost] = minimum_cost || 0
      costs[:subsidy] = 0
      return costs
    end

    duration = (end_at - start_at) / 60
    discount = calculate_discount start_at, end_at

    costs[:cost] = calculate_cost duration, discount
    costs[:subsidy] = calculate_subsidy duration, discount

    if (costs[:cost] - costs[:subsidy]) < minimum_cost.to_f
      costs[:cost] = minimum_cost
      costs[:subsidy] = 0
    end

    costs
  end


  def calculate_cost(duration_mins, discount)
    duration_mins * rate_per_minute * discount
  end


  def calculate_subsidy(duration_mins, discount)
    duration_mins * subsidy_per_minute * discount
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
    case charge_for
      when CHARGE_FOR[:usage] then calculate_usage(reservation)
      when CHARGE_FOR[:overage] then calculate_overage(reservation)
      when CHARGE_FOR[:reservation] then calculate_reservation(reservation)
    end
  end


  def calculate_usage(reservation)

  end


  def calculate_overage(reservation)

  end


  def calculate_reservation(reservation)

  end
end
