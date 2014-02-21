class InstrumentDayReportsController < ReportsController
  include InstrumentReporter

  def reserved_quantity
    render_report(4, nil) { |res| Reports::InstrumentDayReport::ReservedQuantity.new(res) }
  end

  def reserved_hours
    render_report(5, nil) { |res| Reports::InstrumentDayReport::ReservedHours.new(res) }
  end

  def actual_quantity
    render_report(6, nil) { |res| Reports::InstrumentDayReport::ActualQuantity.new(res) }
  end

  def actual_hours
    render_report(7, nil) { |res| Reports::InstrumentDayReport::ActualHours.new(res) }
  end

  private

  def init_report_headers(report_on_label)
    @headers ||= [ 'Instrument', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' ]
  end

  def init_report(report_on_label, &report_on)
    report = Reports::InstrumentDayReport.new(report_data)
    report.build_report &report_on
    @totals = report.totals
    rows = report.rows

    page_report rows
  end

  def init_report_data(report_on_label, &report_on)
    @report_data=report_data.all
    reservation=@report_data.first
    @headers += report_attributes(reservation, reservation.product)
  end

end
