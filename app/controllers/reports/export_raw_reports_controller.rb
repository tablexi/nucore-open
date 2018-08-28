# frozen_string_literal: true

module Reports

  class ExportRawReportsController < CsvExportController

    include StatusFilterParams

    private

    def raw_report
      Reports::ExportRaw.new(
        facility_url_name: current_facility.url_name,
        date_range_field: params[:date_range_field],
        date_start: @date_start,
        date_end: @date_end,
        order_status_ids: @status_ids,
      )
    end

    def success_redirect_path
      facility_general_reports_path(current_facility, report_by: :product)
    end

  end

end
