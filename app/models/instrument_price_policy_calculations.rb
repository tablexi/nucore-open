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

    calculate_for_time(start_at, end_at)
  end

  def calculate_cost_and_subsidy(reservation)
    return calculate_cancellation_costs(reservation) if reservation.canceled_at

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

  # TODO: Move specs to TimeBasedPriceCalculator
  def calculate_discount(start_at, end_at)
    PricePolicies::TimeBasedPriceCalculator.new(self).calculate_discount(start_at, end_at)
  end

  private

  def calculate_for_time(start_at, end_at)
    PricePolicies::TimeBasedPriceCalculator.new(self).calculate(start_at, end_at)
  end

  # CHARGE_FOR[:reservation] uses reserve start and end time for calculation
  def calculate_reservation(reservation)
    calculate_for_time(reservation.reserve_start_at, reservation.reserve_end_at)
  end

  # Usage rate uses the actual start/end times for calculation
  def calculate_usage(reservation)
    return unless reservation.actual_start_at && reservation.actual_end_at
    calculate_for_time(reservation.actual_start_at, reservation.actual_end_at)
  end

  # Overage charges for all the time that was initially reserved, plus any actual
  # time used beyond the scheduled end time.
  def calculate_overage(reservation)
    return unless reservation.actual_start_at && reservation.actual_end_at
    end_at = [reservation.reserve_end_at, reservation.actual_end_at].max
    calculate_for_time(reservation.reserve_start_at, end_at)
  end


  def calculate_cancellation_costs(reservation)
    if cancellation_penalty?(reservation)
      { cost: cancellation_cost, subsidy: 0 }
    end
  end

end
