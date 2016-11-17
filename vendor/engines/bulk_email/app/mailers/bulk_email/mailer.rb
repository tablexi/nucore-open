module BulkEmail

  class Mailer < BaseMailer

    def send_mail(recipient:, subject:, body:)
      @recipient = recipient
      @body = body
      mail(to: recipient.email, subject: subject)
    end

  end

end
