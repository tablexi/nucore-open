module BulkEmail

  class Mailer < BaseMailer

    def send_mail(recipient:, custom_subject:, facility:, custom_message:, product: nil)
      @recipient = recipient
      @facility = facility
      @custom_subject = custom_subject
      @product = product
      @body = content_generator.wrap_text(custom_message)
      mail(to: recipient.email, subject: subject)
    end

    def subject
      "#{content_generator.subject_prefix} #{@custom_subject}"
    end

    private

    def content_generator
      @content_generator ||= ContentGenerator.new(@facility, @product, @recipient)
    end

  end

end
