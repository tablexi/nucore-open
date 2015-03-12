class AutoExpire
  def perform
    order_details.each do |od|
      od.transaction do
        expire_reservation(od)
      end
    end
  end

  private

  def order_details
    purchased_active_order_details | non_reservation_order_details
  end

  def purchased_active_order_details
    OrderDetail.purchased_active_reservations
      .where("reservations.reserve_end_at < ?", Time.zone.now - 12.hours)
      .readonly(false)
      .all
  end

  def non_reservation_order_details
    OrderDetail.purchased_active_reservations
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
    STDERR.puts "Error on Order # #{od} - #{e}\n#{e.backtrace.join("\n")}"
    raise ActiveRecord::Rollback
  end
end
