module Reports

  class InstrumentDayReportsController < ReportsController

    include InstrumentReporter
    helper_method :report_data_row

    def self.reports
      @reports ||= HashWithIndifferentAccess.new(
        reserved_quantity: -> (res) { Reports::InstrumentDayReport::ReservedQuantity.new(res) },
        reserved_hours: -> (res) { Reports::InstrumentDayReport::ReservedHours.new(res) },
        actual_quantity: -> (res) { Reports::InstrumentDayReport::ActualQuantity.new(res) },
        actual_hours: -> (res) { Reports::InstrumentDayReport::ActualHours.new(res) },
      )
    end

    protected

    def tab_offset
      InstrumentReportsController.reports.size
    end

    private

    def init_report_headers
      @headers ||= [text("instrument")] + I18n.t("date.day_names")
    end

    def init_report(&report_on)
      report = Reports::InstrumentDayReport.new(report_data)
      report.build_report(&report_on)
      @totals = report.totals
      rows = report.rows

      page_report rows
    end

    def init_report_data
      @report_data = report_data
      reservation = @report_data.first
      @headers += report_attributes(reservation, reservation.product)
    end

    def report_data_row(reservation)
      row = Array.new(7)
      stat = @report_on.call(reservation)
      row[stat.day] = stat.value
      row.unshift(reservation.product.name) + report_attribute_values(reservation, reservation.product)
    end

  end

end
