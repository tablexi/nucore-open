module InstrumentReporter

  # class ReservationQuerier < Reports::Querier
  #   def initialize(options = {})
  #     super
  #   end

  #   def order_details(options = {})
  #     super.joins(:reservation).where(reservations: { canceled_at: nil })
  #   end
  # end


  def report_data
    # ReservationQuerier.new(
    #   order_status_id: [OrderStatus.complete_status, OrderStatus.complete_status],
    #   current_facility: current_facility,
    #   date_range_field: :fulfilled_at,
    #   date_range_start: @date_start,
    #   date_range_end: @date_end,
    # ).perform.map(&:reservation)

    reservations = Reservation.where(%q/orders.facility_id = ? AND fulfilled_at >= ? AND fulfilled_at <= ? AND canceled_at IS NULL AND (order_details.state IS NULL OR order_details.state = 'complete' OR order_details.state = 'reconciled')/, current_facility.id, @date_start, @date_end).
               joins('LEFT JOIN order_details ON reservations.order_detail_id = order_details.id INNER JOIN orders ON order_details.order_id = orders.id').
               includes(:product)

    Reports::TransformerFactory.instance(reservations.map(&:order_detail)).perform.map(&:reservation)
  end

end
