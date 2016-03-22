module InstrumentReporter

  def report_data
    reservations = Reservation.where("orders.facility_id = ?", current_facility.id)
                              .where("fulfilled_at >= ?", @date_start)
                              .where("fulfilled_at <= ?", @date_end)
                              .where(canceled_at: nil)
                              .where(order_details: { state: %w(complete reconciled) })
                              .joins(:order_detail)
                              .joins(order_detail: :order)
                              .includes(:product)
                              .includes(:order_detail)

    order_details = reservations.map(&:order_detail)
    virtual_order_details = OrderDetailListTransformerFactory.instance(order_details).perform(reservations: true)
    virtual_order_details.map(&:reservation)
  end

end
