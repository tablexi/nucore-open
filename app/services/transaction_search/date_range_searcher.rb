module TransactionSearch

  class DateRangeSearcher < BaseSearcher

    include DateHelper
    FIELDS = %w(ordered_at fulfilled_at journal_or_statement_date reconciled_at).freeze

    attr_reader :date_range_field

    def self.options
      if @billing_context
        FIELDS.map { |field| [I18n.t(field, scope: "admin.transaction_search.date_range_fields"), field] }
      else
        [[I18n.t("ordered_at", scope: "admin.transaction_search.date_range_fields"), "ordered_at"]]
      end
    end

    def options
      self.class.options
    end

    def multipart?
      true
    end

    def search(params)
      params ||= {}
      start_date = to_date(params[:start])
      end_date = to_date(params[:end])
      @date_range_field = extract_date_range_field(params)

      if start_date.present? || end_date.present?
        order_details
          .action_in_date_range(@date_range_field, start_date, end_date)
          .ordered_by_action_date(@date_range_field)
      else
        order_details
      end

    end

    def to_date(param_value)
      parse_usa_date(param_value.to_s.tr("-", "/"))
    end

    def extract_date_range_field(params)
      field = params.try(:[], :field)
      FIELDS.include?(field.to_s) ? field.to_s : "fulfilled_at"
    end

  end

end
