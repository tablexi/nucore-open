# frozen_string_literal: true

class InstrumentIssueMailerPreview < ActionMailer::Preview

  def create
    reservation = NUCore::Database.random(Reservation.user)
    InstrumentIssueMailer.create(
      instrument: reservation.product,
      user: reservation.user,
      message: "I am having a problem with the #{reservation.product}. Please help!"
    )
  end

end
