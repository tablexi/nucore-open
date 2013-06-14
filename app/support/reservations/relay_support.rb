module Reservations::RelaySupport
  def can_switch_instrument_on?(check_off = true)
    return false if cancelled?
    return false unless product.relay   # is relay controlled
    return false if can_switch_instrument_off?(false) if check_off # mutually exclusive
    return false unless actual_start_at.nil?   # already turned on
    return false unless actual_end_at.nil?     # already turned off
    return false if reserve_end_at < Time.zone.now # reservation is already over (missed reservation)
    return can_start_early? if reserve_start_at > Time.zone.now
    true
  end

  def can_switch_instrument_off?(check_on = true)
    return false unless product.relay  # is relay controlled
    return false if can_switch_instrument_on?(false) if check_on  # mutually exclusive
    return false unless actual_end_at.nil?    # already ended
    return false if actual_start_at.nil?      # hasn't been started yet
    return false if order_detail.complete?
    true
  end

  def can_switch_instrument?
    return can_switch_instrument_off? || can_switch_instrument_on?
  end

  def can_kill_power?
    return false if actual_start_at.nil?
    return false unless Reservation.find(:first, :conditions => ['actual_start_at > ? AND product_id = ? AND id <> ? AND actual_end_at IS NULL', actual_start_at, product_id, id]).nil?
    true
  end
  deprecate :can_kill_power? => 'Most likely not used anywhere'
end