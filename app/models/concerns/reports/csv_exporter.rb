module Reports

  module CsvExporter

    extend ActiveSupport::Concern

    include DateHelper
    include TextHelpers::Translation

    module ClassMethods

      def transformers
        @@transformers ||= []
      end

    end

    def date_start
      @date_start.in_time_zone
    end

    def date_end
      @date_end.in_time_zone
    end

    def report_data
      @report_data ||= report_data_query
    end

    def to_csv
      (csv_header + csv_body).to_s
    end

    def filename
      "#{facility.name.underscore}_#{formatted_compact_date_range}.csv"
    end

    def formatted_date_range
      "#{format_usa_date(date_start)} - #{format_usa_date(date_end)}"
    end

    def formatted_compact_date_range
      "#{date_start.strftime('%Y%m%d')}-#{date_end.strftime('%Y%m%d')}"
    end

    def column_headers
      report_hash.keys.map do |key|
        text(".headers.#{key}", default: key.to_s.titleize)
      end
    end

    private

    def csv_header
      column_headers.join(",") + "\n"
    end

    def report_hash
      transformers.reduce(default_report_hash) do |result, class_name|
        class_name.constantize.new.transform(result)
      end
    end

    def transformers
      self.class.transformers
    end

  end

end
