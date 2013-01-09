class InstrumentDayReportsController < ReportsController
  include InstrumentReporter


  def reserved_quantity
    render_report(4, nil) {|res| [ res.reserve_start_at.wday, 1 ] }
  end


  def reserved_hours
    render_report(5, nil) {|res| [ res.reserve_start_at.wday, to_hours(res.duration_mins) ] }
  end


  def actual_quantity
    render_report(6, nil) {|res| res.actual_start_at ? [ res.actual_start_at.wday, 1 ] : nil }
  end


  def actual_hours
    render_report(7, nil) {|res| res.actual_start_at ? [ res.actual_start_at.wday, to_hours(res.actual_duration_mins) ] : nil }
  end


  private

  def init_report_headers(report_on_label)
    @headers ||= [ 'Instrument', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' ]
  end


  def init_report(report_on_label, &report_on)
    instruments={}

    report_data.all.each do |res|
      stat=yield res
      next unless stat
      ndx, value=stat[0], stat[1]
      instrument=res.product.name
      days=instruments[instrument]

      if days.blank?
        instruments[instrument]=[0,0,0,0,0,0,0]
        instruments[instrument][ndx]=value
      else
        days[ndx]+=value
      end
    end

    rows, @totals=[], [0,0,0,0,0,0,0]

    instruments.each do |k,v|
      @totals.each_index{|i| @totals[i] += v[i]}
      rows << v.unshift(k)
    end

    page_report rows
  end


  def init_report_data(report_on_label, &report_on)
    @report_data=report_data.all
    reservation=@report_data.first
    @headers += report_attributes(reservation, reservation.product)
  end

end