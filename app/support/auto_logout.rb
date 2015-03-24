class AutoLogout
  def perform
    order_details.each do |od|
      next unless od.product.relay.try(:auto_logout) == true

      od.transaction do
        complete_reservation(od)
      end
    end
  end

  private

  def order_details
    OrderDetail.purchased_active_reservations.
      where("reservations.actual_end_at IS NULL AND reserve_end_at < ?", Time.zone.now - 1.hour).
      includes(:product).
      readonly(false).all
  end

  def complete_status
    @complete_status ||= OrderStatus.find_by_name!('Complete')
  end

  def complete_reservation(od)
    deactivate_relay = od.reservation.other_reservation_using_relay?
    od.reservation.product.relay.deactivate if deactivate_relay
    od.reservation.end_reservation!
  rescue => e
    STDERR.puts "Error on Order # #{od} - #{e}"
    raise ActiveRecord::Rollback
  end
end
