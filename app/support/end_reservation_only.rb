class EndReservationOnly
  def perform
    order_details.each do |od|
      od.transaction do
        expire_reservation(od)
      end
    end
  end

  private

  def order_details
    reservation_only_order_details
  end

  def reservation_only_order_details
    OrderDetail.purchased_active_reservations
      .merge(Reservation.in_progress)
      .where("reservations.reserve_end_at < ?", Time.zone.now)
      .joins(:product)
      .merge(Instrument.reservation_only)
      .readonly(false)
  end

  def expire_reservation(od)
    od.fulfilled_at = od.reservation.reserve_end_at
    od.assign_actual_price
    od.complete!
  rescue => e
    ActiveSupport::Notifications.instrument('background_error',
        exception: e, information: "Failed expire reservation order detail with id: #{od.id}")
    raise ActiveRecord::Rollback
  end
end
