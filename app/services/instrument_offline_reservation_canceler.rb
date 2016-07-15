class InstrumentOfflineReservationCanceler

  def cancel!
    reservations_to_cancel.each do |reservation|
      reservation.transaction do
        cancel_reservation(reservation)
        OfflineCancellationMailer.delay.send_notification(reservation)
      end
    end
  end

  private

  def admin_user
    # OrderDetail#cancel_reservation needs an object that responds to #id
    @admin_user ||= OpenStruct.new(id: 0)
  end

  def cancel_reservation(reservation)
    reservation
      .order_detail
      .cancel_reservation(admin_user, OrderStatus.canceled.first, true, false)
    reservation
      .update_attribute(:canceled_reason, "The instrument was offline")
  end

  def reservations_to_cancel
    Reservation
      .user
      .where(product_id: offline_instrument_ids)
      .not_canceled
      .not_ended
      .where("reserve_start_at <= ?", Time.current)
  end

  def offline_instrument_ids
    Instrument.where(schedule_id: offline_schedule_ids)
  end

  def offline_schedule_ids
    OfflineReservation.current.joins(:product).pluck(:schedule_id)
  end

end
