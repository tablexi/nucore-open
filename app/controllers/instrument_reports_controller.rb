class InstrumentReportsController < ReportsController
  include InstrumentReporter


  def instrument
    render_report(0, nil) {|r| [ r.product.name ] }
  end


  def account
    render_report(1, 'Description') {|r| [ r.product.name, r.order_detail.account.to_s ]}
  end


  def account_owner
    render_report(2, 'Name') do |r|
      owner=r.order_detail.account.owner.user
      [ r.product.name, format_username(owner) ]
    end
  end


  def purchaser
    render_report(3, 'Name') do |r|
      usr=r.order_detail.order.user
      [ r.product.name, format_username(usr) ]
    end
  end


  private

  def init_report_headers(report_on_label)
    @headers=[ 'Instrument', 'Quantity', 'Reserved Time (h)', 'Percent of Reserved', 'Actual Time (h)', 'Percent of Actual Time' ]
    @headers.insert(1, report_on_label) if report_on_label
  end


  def init_report(report_on_label, &report_on)
    report = Reports::InstrumentUtilizationReport.new(report_data)
    report.build_report &report_on

    @totals = report.totals
    @label_columns = report.key_length

    rows = report.rows
    page_report(rows)
  end


  def init_report_data(report_on_label, &report_on)
    @totals, @report_data=[0,0], report_data.all

    @report_data.each do |res|
      @totals[0] += to_hours(res.duration_mins)
      @totals[1] += to_hours(res.actual_duration_mins)
    end

    reservation=@report_data.first
    @headers += report_attributes(reservation, reservation.product)
  end

end
