class InstrumentReportsController < ReportsController
  include InstrumentReporter


  def instrument
    render_report(0, nil) {|r| [ r.instrument.name ] }
  end


  def account
    render_report(1, 'Description') {|r| [ r.instrument.name, r.order_detail.account.to_s ]}
  end
  

  def account_owner
    render_report(2, 'Name') do |r|
      owner=r.order_detail.account.owner.user
      [ r.instrument.name, format_username(owner) ]
    end
  end


  def purchaser
    render_report(3, 'Name') do |r|
      usr=r.order_detail.order.user
      [ r.instrument.name, format_username(usr) ]
    end
  end


  private

  def init_report_headers(report_on_label)
    @headers=[ 'Instrument', 'Quantity', 'Reserved Time (h)', 'Percent of Reserved', 'Actual Time (h)', 'Percent of Actual Time' ]
    @headers.insert(1, report_on_label) if report_on_label
  end


  def init_report(report_on_label, &report_on)
    sums, rows, @totals={}, [], [0,0,0]

    report_data.all.each do |res|
      key=yield res
      sums[key]=[0,0,0] unless sums.has_key?(key)

      # number of reservations
      sums[key][0] += 1
      @totals[0] += 1

      # total reserved minutes of reservations
      reserved_hours=to_hours(res.duration_mins)
      sums[key][1] += reserved_hours
      @totals[1] += reserved_hours

      # total actual minutes of reservations
      actual_hours=to_hours(res.actual_duration_mins)
      sums[key][2] += actual_hours
      @totals[2] += actual_hours
    end

    sums.each do |k,v|
      percent_reserved=to_percent(@totals[1] > 0 ? v[1] / @totals[1] : 1)
      percent_actual=to_percent(@totals[2] > 0 ? v[2] / @totals[2] : 1)
      rows << (k + v.insert(2, percent_reserved).push(percent_actual))
    end

    rows.sort! {|a,b| a.first <=> b.first}
    page_report(rows)
  end


  def init_report_data(report_on_label, &report_on)
    @totals, @report_data=[0,0], report_data.all

    @report_data.each do |res|
      @totals[0] += to_hours(res.duration_mins)
      @totals[1] += to_hours(res.actual_duration_mins)
    end

    reservation=@report_data.first
    @headers += report_attributes(reservation, reservation.instrument)
  end

end