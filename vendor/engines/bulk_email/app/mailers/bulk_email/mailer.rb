module BulkEmail

  class Mailer < BaseMailer

    def send_mail(recipient:, subject:, body:, reply_to: nil, facility:)
      @recipient = recipient
      @body = body
      options = { from: sender(facility), to: recipient.email, subject: subject }
      options[:reply_to] = reply_to if reply_to.present?
      mail(options)
    end

    def sender(facility)
      if facility.try(:single_facility?)
        "#{facility.name} <#{Settings.email.from}>"
      else
        Settings.email.from
      end
    end

  end

end
