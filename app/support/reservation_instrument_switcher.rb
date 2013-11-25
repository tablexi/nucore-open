class ReservationInstrumentSwitcher
  attr_reader :reservation

  def initialize(reservation)
    @reservation = reservation
  end

  def switch_on!
    raise relay_error_msg unless reservation.can_switch_instrument_on?

    if switch_relay_on
      @reservation.actual_start_at = Time.zone.now
      grace_period_update if in_grace_period?
      @reservation.save!
    else
      raise relay_error_msg
    end
    instrument.instrument_statuses.create(:is_on => true)
  end

  def switch_off!
    raise relay_error_msg unless reservation.can_switch_instrument_off?

    if switch_relay_off == false
      @reservation.actual_end_at = Time.zone.now
      @reservation.save!
    else
      raise relay_error_msg
    end
    instrument.instrument_statuses.create(:is_on => false)

    # reservation is done, now give the best price
    @reservation.order_detail.assign_price_policy
    @reservation.order_detail.save!
  end

  private

  def switch_relay_off
    if relays_enabled?
      relay.deactivate
      relay.get_status
    else
      false
    end
  end

  def switch_relay_on
    if relays_enabled?
      relay.activate
      relay.get_status
    else
      true
    end
  end

  def relays_enabled?
    Rails.env.production?
  end

  def grace_period_update
    reservation.grace_period_update = true
    # Move the reservation time forward so other reservations can't overlap
    # with this one, but only move it forward if there's not already a reservation
    # currently in progress.
    original_start_at = @reservation.reserve_start_at
    @reservation.reserve_start_at = @reservation.actual_start_at
    unless @reservation.does_not_conflict_with_other_reservation?
      @reservation.reserve_start_at = original_start_at
    end
  end

  def instrument
    reservation.product
  end

  def relay
    instrument.relay
  end

  def in_grace_period?
    @reservation.reserve_start_at > @reservation.actual_start_at
  end

  def relay_error_msg
    'An error was encountered while attempted to toggle the instrument. Please try again.'
  end
end
