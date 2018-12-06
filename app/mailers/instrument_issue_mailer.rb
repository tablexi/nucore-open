# frozen_string_literal: true

class InstrumentIssueMailer < BaseMailer

  def create(instrument:, user:, message:)
    @instrument = instrument
    @user = user
    @message = message
    users = ["test@example.com"]
    mail(to: users, subject: text("create.subject", instrument: instrument))
  end

  protected

  def translation_scope
    "views.#{self.class.name.underscore}"
  end

end
