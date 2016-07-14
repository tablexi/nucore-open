class UpcomingOfflineReservationNotifier

  def notify
    upcoming_offline_reservations.each do |reservation|
      Notifier.upcoming_offline_reservation_notification(reservation)
    end
  end

  private

  def offline_instrument_ids
    Instrument.where(schedule_id: offline_schedule_ids)
  end

  def offline_schedule_ids
    OfflineReservation.current.joins(:product).pluck(:schedule_id)
  end

  def upcoming_offline_reservations
    Reservation
      .not_offline
      .where(product_id: offline_instrument_ids)
      .not_canceled
      .not_ended
      .where("reserve_start_at <= ?", Time.current + 1.day)
  end
end
