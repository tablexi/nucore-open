# frozen_string_literal: true

class UpcomingOfflineReservationNotifier

  def notify
    Reservation.upcoming_offline(1.day.from_now).each do |reservation|
      UpcomingOfflineReservationMailer
        .with(reservation: reservation)
        .send_offline_instrument_warning
        .deliver_later
    end
  end

end
