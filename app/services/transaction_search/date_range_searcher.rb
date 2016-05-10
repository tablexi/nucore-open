module TransactionSearch

  class DateRangeSearcher < BaseSearcher

    include DateHelper
    FIELDS = %w(ordered_at fulfilled_at journal_or_statement_date).freeze

    attr_reader :date_range_field

    def self.options
      FIELDS.map { |field| [I18n.t(field, scope: "admin.transaction_search.date_range_fields"), field] }
    end

    def options
      self.class.options
    end

    def search(params)
      start_date = parse_usa_date(params.try(:[], :start).to_s.tr("-", "/"))
      end_date = parse_usa_date(params.try(:[], :end).to_s.tr("-", "/"))
      @date_range_field = extract_date_range_field(params)
      order_details.action_in_date_range(@date_range_field, start_date, end_date)
    end

    private

    def extract_date_range_field(params)
      field = params.try(:[], :field)
      FIELDS.include?(field) ? field : "fulfilled_at"
    end

  end

end
