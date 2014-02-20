module InstrumentReporter

  def report_data
    Reservation.where(%q/orders.facility_id = ? AND fulfilled_at >= ? AND fulfilled_at <= ? AND canceled_at IS NULL AND (order_details.state IS NULL OR order_details.state = 'complete' OR order_details.state = 'reconciled')/, current_facility.id, @date_start, @date_end).
               joins('LEFT JOIN order_details ON reservations.order_detail_id = order_details.id INNER JOIN orders ON order_details.order_id = orders.id').
               includes(:product)
  end

end
