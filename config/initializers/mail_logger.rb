class MailLogger < ActiveSupport::LogSubscriber
  def deliver(event)
    info do
      event.payload
    end
  end
end

MailLogger.attach_to :action_mailer
