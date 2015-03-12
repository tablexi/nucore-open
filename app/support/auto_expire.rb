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
    od.change_status!(OrderStatus.complete_status)
    od.fulfilled_at = od.reservation.reserve_end_at
    return unless od.price_policy
    costs = od.price_policy.calculate_cost_and_subsidy(od.reservation)
    return if costs.blank?
    od.actual_cost    = costs[:cost]
    od.actual_subsidy = costs[:subsidy]
    od.save!
  rescue => e
    STDERR.puts "Error on Order # #{od} - #{e}\n#{e.backtrace.join("\n")}"
    raise ActiveRecord::Rollback
  end
end
