module BulkEmail

  class Mailer < BaseMailer

    def send_mail(recipient:, custom_subject:, facility:, custom_message:)
      @recipient = recipient
      @facility = facility
      @custom_message = custom_message
      @custom_subject = custom_subject
      mail(to: recipient.email, subject: subject)
    end

    def subject
      "[#{I18n.t('app_name')} #{@facility.name}] #{@custom_subject}"
    end

  end

end
