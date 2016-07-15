class OfflineCancellationMailer < BaseMailer

  attr_reader :reservation

  def send_notification(reservation_id)
    @reservation = Reservation.find(reservation_id)
    @instrument = reservation.product
    mail(to: reservation.user.email, subject: subject)
  end

  private

  def subject
    text(
      "views.notifier.offline_cancellation_notification.subject",
      instrument: reservation.product,
    )
  end

end
