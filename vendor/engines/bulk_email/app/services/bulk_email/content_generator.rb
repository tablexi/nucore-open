module BulkEmail

  class ContentGenerator

    attr_reader :facility, :subject_product, :recipient

    def initialize(facility, subject_product = nil, recipient = nil)
      @facility = facility
      @subject_product = subject_product
      @recipient = recipient
    end

    def subject_prefix
      "[#{I18n.t('app_name')} #{facility.name}]"
    end

    def wrap_text(text)
      [greeting, text, signoff].join("\n\n")
    end

    def greeting
      [
        I18n.t("bulk_email.body.greeting", recipient_name: recipient_name),
        reason_statement,
      ].compact.join("\n")
    end

    def signoff
      I18n.t("bulk_email.body.signoff", facility_name: facility.name)
    end

    private

    def reason_statement
      return if subject_product.blank? || subject_product.online?
      I18n.t(subject_product.offline_category,
             product_name: subject_product.name,
             scope: "bulk_email.product_unavailable_reason_statements",
             default: :other)
    end

    def recipient_name
      recipient.try(:full_name) || "Firstname Lastname"
    end

  end

end
