class InstrumentReportsController < ReportsController


  def instrument
    render_report(0, nil) {|r| [ r.instrument.url_name ] }
  end


  def account
    render_report(1, 'Description') {|r| [ r.instrument.url_name, r.order_detail.account.to_s ]}
  end
  

  def account_owner
    render_report(2, 'Name') do |r|
      owner=r.order_detail.account.owner.user
      [ r.instrument.url_name, "#{owner.full_name} (#{owner.username})" ]
    end
  end


  def purchaser
    render_report(3, 'Name') do |r|
      usr=r.order_detail.order.user
      [ r.instrument.url_name, "#{usr.full_name} (#{usr.username})" ]
    end
  end


  private

  def init_report_headers(report_on_label)
    @headers=[ 'Instrument', 'Quantity', 'Reserved Time (h)', 'Percent of Reserved', 'Actual Time (h)', 'Percent of Actual Time' ]
    @headers.insert(1, report_on_label) if report_on_label
  end


  def init_report(report_on_label, &report_on)
    sums, rows, @totals={}, [], [0,0,0]
    init_report_headers report_on_label

    report_data.all.each do |res|
      key=yield res
      sums[key]=[0,0,0] unless sums.has_key?(key)

      # number of reservations
      sums[key][0] += 1
      @totals[0] += 1

      # total reserved minutes of reservations
      sums[key][1] += res.duration_mins
      @totals[1] += res.duration_mins

      # total actual minutes of reservations
      sums[key][2] += res.actual_duration_mins
      @totals[2] += res.actual_duration_mins
    end

    sums.each do |k,v|
      frac_reserved=@totals[1] > 0 ? v[1] / @totals[1] : 1
      frac_actual=@totals[2] > 0 ? v[2] / @totals[2] : 1
      rows << (k + v.insert(2, frac_reserved * 100).push(frac_actual * 100))
    end

    rows.sort! {|a,b| a.first <=> b.first}
    page_report(rows)
  end


  def init_report_data(report_on_label, &report_on)
    raise 'Subclass must implement!'
  end


  def report_data
    Reservation.where(%q/orders.facility_id = ? AND reserve_start_at >= ? AND reserve_start_at <= ? AND canceled_at IS NULL AND (order_details.state IS NULL OR order_details.state = 'complete')/, current_facility.id, @date_start, @date_end).
               joins('LEFT JOIN order_details ON reservations.order_detail_id = order_details.id INNER JOIN orders ON order_details.order_id = orders.id').
               includes(:instrument)
  end

end