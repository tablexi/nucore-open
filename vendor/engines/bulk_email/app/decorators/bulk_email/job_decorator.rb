# frozen_string_literal: true

module BulkEmail

  class JobDecorator < SimpleDelegator

    def to_model
      self
    end

    def sender
      user.email
    end

    def recipient_list
      recipients.join(", ")
    end

    def products
      @products ||=
        Product.where(id: selected_product_ids).pluck(:name).join(", ")
    end

    def start_date
      search_criteria["start_date"] || I18n.t("bulk_email.dates.unset")
    end

    def end_date
      search_criteria["end_date"] || I18n.t("bulk_email.dates.unset")
    end

    def user_types
      search_criteria["bulk_email"]["user_types"].map do |user_type|
        I18n.t(user_type, scope: "bulk_email.user_type", default: user_type.titleize)
      end.join(", ")
    end

    private

    def selected_product_ids
      ((search_criteria["products"] || []) << search_criteria["product_id"])
        .compact
        .map(&:to_i)
        .uniq
    end

  end

end
