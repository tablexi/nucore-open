module Reports

  class ExportRawReportsController < ReportsController

    include CsvExportController
    include StatusFilterParams

    private

    def raw_report
      Reports::ExportRaw.new(
        facility: current_facility,
        date_range_field: params[:date_range_field],
        date_start: @date_start,
        date_end: @date_end,
        order_status_ids: @status_ids,
      )
    end

    def success_redirect_path
      public_send("#{action_name}_facility_general_reports_path", current_facility)
    end

  end

end
