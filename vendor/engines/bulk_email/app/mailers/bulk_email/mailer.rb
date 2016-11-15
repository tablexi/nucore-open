module BulkEmail

  class Mailer < BaseMailer

    def send_mail(recipient:, custom_subject:, custom_message:)
      @recipient = recipient
      @body = custom_message
      mail(to: recipient.email, subject: custom_subject)
    end

  end

end
