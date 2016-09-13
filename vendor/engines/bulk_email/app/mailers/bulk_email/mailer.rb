module BulkEmail

  class Mailer < BaseMailer

    def send_mail(recipient:, subject:, facility:, custom_message:)
      @recipient = recipient
      @facility = facility
      @custom_message = custom_message
      mail(to: recipient.email, subject: subject)
    end

  end

end
