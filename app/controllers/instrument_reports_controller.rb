class InstrumentReportsController < ReportsController


  def instrument
    render_report(0, 'Name')
  end


  def account
    render_report(1, 'Number')
  end
  

  def account_owner
    render_report(2, 'Name')
  end


  def purchaser
    render_report(3, 'Name')
  end


  private

  def init_report_headers(report_on_label)
    @headers=[ 'Instrument', report_on_label, 'Quantity', 'Reserved Time (h)', 'Percent of Reserved', 'Actual Time (h)', 'Percent of Actual Time' ]
  end


  def init_report(report_on_label, &report_on)
    raise 'Subclass must implement!'
  end


  def init_report_data(report_on_label, &report_on)
    raise 'Subclass must implement!'
  end


  def report_data
    render_report_download 'instrument_utilization' do
      Reservation.where(%q/orders.facility_id = ? AND reserve_start_at >= ? AND reserve_start_at <= ? AND canceled_at IS NULL AND (order_details.state IS NULL OR order_details.state = 'complete')/, current_facility.id, @date_start, @date_end).
                 joins('LEFT JOIN order_details ON reservations.order_detail_id = order_details.id INNER JOIN orders ON order_details.order_id = orders.id').
                 includes(:instrument).
                 order('reserve_start_at ASC').all
    end
  end

end