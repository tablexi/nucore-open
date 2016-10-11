module BulkEmail

  class Mailer < BaseMailer

    def send_mail(recipient:, custom_subject:, facility:, custom_message:, subject_product_id: nil)
      @recipient = recipient
      @facility = facility
      @custom_subject = custom_subject
      @subject_product = Product.find(subject_product_id) if subject_product_id.present?
      @body = content_generator.wrap_text(custom_message)
      mail(to: recipient.email, subject: subject)
    end

    def subject
      "#{content_generator.subject_prefix} #{@custom_subject}"
    end

    private

    def content_generator
      @content_generator ||=
        ContentGenerator.new(@facility, @subject_product, @recipient)
    end

  end

end
