class MailerPreview < ActionMailer::Preview

  def upcoming_offline_reservation
    UpcomingOfflineReservationMailer.generate_mail(Reservation.user.first)
  end

end
