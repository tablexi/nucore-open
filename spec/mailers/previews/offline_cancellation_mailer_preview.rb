# frozen_string_literal: true

class OfflineCancellationMailerPreview < ActionMailer::Preview

  def offline_cancellation
    OfflineCancellationMailer.with(reservation: Reservation.user.last).send_notification
  end

end
