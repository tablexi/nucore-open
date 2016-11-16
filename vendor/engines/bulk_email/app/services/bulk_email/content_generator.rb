module BulkEmail

  class ContentGenerator

    DEFAULT_RECIPIENT_NAME = "Firstname Lastname".freeze

    attr_reader :facility, :subject_product

    def initialize(facility, subject_product = nil)
      @facility = facility
      @subject_product = subject_product
    end

    def subject_prefix
      "[#{I18n.t('app_name')} #{facility.name}]"
    end

    def wrap_text(text, recipient_name = nil)
      [greeting(recipient_name), text, signoff].join("\n\n")
    end

    def greeting(recipient_name = nil)
      [
        I18n.t("bulk_email.body.greeting", recipient_name: recipient_name || DEFAULT_RECIPIENT_NAME),
        reason_statement,
      ].compact.join("\n\n")
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

  end

end
