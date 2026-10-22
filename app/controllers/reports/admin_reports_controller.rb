# frozen_string_literal: true

module Reports

  class AdminReportsController < GlobalSettingsController

    include CsvEmailAction

    def index
      @reports = Reports::AdminReport.all
    end

    def show
      report = Reports::AdminReport.find(params[:key])
      raise ActiveRecord::RecordNotFound unless report

      queue_csv_report_email(report.report_class, fallback_location: admin_reports_path, **report_args(report))
    end

    private

    def report_args(report)
      return {} if report.filters.empty?

      params.permit(*report.filters).to_h.symbolize_keys.compact_blank
    end

  end

end
