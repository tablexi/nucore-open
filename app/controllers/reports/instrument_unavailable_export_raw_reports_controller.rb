module Reports

  class InstrumentUnavailableExportRawReportsController < CsvExportController

    private

    def raw_report
      Reports::InstrumentUnavailableExportRaw.new(
        facility: current_facility,
        date_start: @date_start,
        date_end: @date_end,
      )
    end

    def success_redirect_path
      public_send("#{action_name}_facility_instrument_reports_path", current_facility)
    end

  end

end
