class UpcomingOfflineReservationMailer < BaseMailer

  attr_reader :reservation

  def generate_mail(reservation)
    @reservation = reservation
    mail(to: recipient.email, subject: subject)
  end

  private

  def recipient
    reservation.user
  end

  def subject
    text("upcoming_offline_reservation_mailer.subject",
         instrument: reservation.product)
  end

end
