# frozen_string_literal: true

class UpcomingOfflineReservationMailerPreview < ActionMailer::Preview

  def upcoming_offline_reservation
    UpcomingOfflineReservationMailer
      .with(reservation: Reservation.user.first).send_offline_instrument_warning
  end

end
