class UpcomingOfflineReservationNotifier

  def notify
    Reservation.upcoming_offline.each do |reservation|
      UpcomingOfflineReservationMailer
        .send_offline_instrument_warning(reservation)
        .deliver_later
    end
  end

end
