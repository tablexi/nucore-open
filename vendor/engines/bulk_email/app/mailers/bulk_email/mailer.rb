module BulkEmail

  class Mailer < BaseMailer

    def send_mail(recipient:, subject:, body:, reply_to: nil)
      @recipient = recipient
      @body = body
      options = { to: recipient.email, subject: subject }
      options[:reply_to] = reply_to if reply_to.present?
      mail(options)
    end

  end

end
