module OldInstrumentPricePolicyCalculations

  def estimate_cost_and_subsidy_from_order_detail(order_detail)
    reservation = order_detail.reservation
    estimate_cost_and_subsidy reservation.reserve_start_at, reservation.reserve_end_at if reservation
  end


  def estimate_cost_and_subsidy (start_at, end_at)
    return nil if restrict_purchase? || end_at <= start_at
    costs = {}

    ## the instrument is free to use
    if free?
      costs[:cost]    = minimum_cost || 0
      costs[:subsidy] = 0
      return costs
    end

    duration = (end_at - start_at)/60
    discount = 0
    product.schedule_rules.each do |sr|
      discount += sr.percent_overlap(start_at, end_at) * sr.discount_percent.to_f
    end
    discount = 1 - discount/100

    costs[:cost] = ((duration/reservation_mins).ceil * reservation_rate.to_f + (duration/usage_mins).ceil * usage_rate.to_f) * discount
    costs[:subsidy] = ((duration/reservation_mins).ceil * reservation_subsidy.to_f + (duration/usage_mins).ceil * usage_subsidy.to_f) * discount
    if (costs[:cost] - costs[:subsidy]) < minimum_cost.to_f
      costs[:cost]    = minimum_cost
      costs[:subsidy] = 0
    end
    costs
  end


  def calculate_cost_and_subsidy_from_order_detail(order_detail)
    calculate_cost_and_subsidy order_detail.reservation
  end


  def calculate_cost_and_subsidy (reservation)
    res_end_at=strip_seconds reservation.reserve_end_at
    res_start_at=strip_seconds reservation.reserve_start_at

    ## TODO update cancellation costs
    ## calculate actuals for cancelled reservations
    if reservation.canceled_at
      if product.min_cancel_hours && (res_start_at - strip_seconds(reservation.canceled_at))/3600 <= product.min_cancel_hours
        actual_cost = cancellation_cost
        actual_subsidy = 0
        return {:cost => actual_cost, :subsidy => actual_subsidy}
      else
        ## TODO how to calculate this
        return nil
      end
    end

    ## the instrument has a reservation cost only (i.e. is controlled manually)
    if product.control_mechanism == Relay::CONTROL_MECHANISMS[:manual]
      return nil if reservation_rate.nil? || reservation_subsidy.nil?

      reserve_mins = (res_end_at - res_start_at)/60
      reserve_intervals = (reserve_mins / reservation_mins).ceil
      reserve_discount = 0
      product.schedule_rules.each do |sr|
        reserve_discount += sr.percent_overlap(res_start_at, res_end_at) * sr.discount_percent
      end
      reserve_discount = 1 - reserve_discount/100
      actual_cost = reservation_rate * reserve_intervals * reserve_discount
      actual_subsidy  = reservation_subsidy * reserve_intervals * reserve_discount
      if actual_cost.to_f < minimum_cost.to_f
        actual_cost    = minimum_cost
        actual_subsidy = 0
      end
      return {:cost => actual_cost, :subsidy => actual_subsidy}
    end

    ## make sure actuals are entered
    return nil unless (reservation.actual_start_at && reservation.actual_end_at)

    ## the instrument is free to use, so no costs matter
    if free?
      actual_cost = minimum_cost || 0
      actual_subsidy = 0
      return {:cost => actual_cost, :subsidy => actual_subsidy}
    end

    act_end_at=strip_seconds reservation.actual_end_at
    act_start_at=strip_seconds reservation.actual_start_at

    # calculate reservation cost & subsidy
    reserve_cost = 0
    reserve_sub  = 0
    unless reservation_rate.to_f == 0
      reserve_mins = (res_end_at - res_start_at)/60
      reserve_intervals = (reserve_mins / reservation_mins).ceil
      reserve_discount = 0
      product.schedule_rules.each do |sr|
        reserve_discount += sr.percent_overlap(res_start_at, res_end_at) * sr.discount_percent
      end
      reserve_discount = 1 - reserve_discount/100
      reserve_cost = reservation_rate * reserve_intervals * reserve_discount
      reserve_sub  = reservation_subsidy * reserve_intervals * reserve_discount
    end

    # calculate usage cost & subsidy
    usage_cost = 0
    usage_sub  = 0
    unless usage_rate.to_f == 0
      usage_minutes   = ([act_end_at, res_end_at].min - act_start_at)/60
      usage_intervals = (usage_minutes / usage_mins).ceil
      # Make sure we always have at least one interval
      usage_intervals = [usage_intervals, 1].max
      usage_discount = 0
      product.schedule_rules.each do |sr|
        usage_discount += sr.percent_overlap(act_start_at, [act_end_at, res_end_at].min) * sr.discount_percent
      end
      usage_discount = 1 - usage_discount/100
      usage_cost = usage_rate * usage_intervals * usage_discount
      usage_sub  = usage_subsidy * usage_intervals * usage_discount
    end

    # calculate overage cost & subsidy
    over_cost = 0
    over_sub  = 0
    rate      = 0
    sub       = 0
    if overage_rate.nil?
      rate = usage_rate.to_f
      sub  = usage_subsidy.to_f
    else
      rate = overage_rate.to_f
      sub  = overage_subsidy.to_f
    end
    if act_end_at > res_end_at && rate > 0
      over_mins = (act_end_at - res_end_at)/60
      over_intervals = (over_mins / overage_mins).ceil
      over_cost = rate * over_intervals
      over_sub  = sub * over_intervals
    end

    # calculate total cost & subsidy
    actual_cost    = reserve_cost + usage_cost + over_cost
    actual_subsidy = reserve_sub  + usage_sub  + over_sub
    if actual_cost - actual_subsidy < minimum_cost.to_f
      actual_cost    = minimum_cost
      actual_subsidy = 0
    end
    return {:cost => actual_cost, :subsidy => actual_subsidy}
  end


  private

  def strip_seconds(time)
   Time.zone.parse("#{time.year}-#{time.month}-#{time.day} #{time.hour}:#{time.min}")
  end

end
