class AutoLogout
  def perform
    order_details.each do |od|
      relay = od.product.relay
      next unless relay.try(:auto_logout) == true
      next unless auto_logout_time?(od.reservation.reserve_end_at, relay.try(:auto_logout_minutes))

      od.transaction do
        complete_reservation(od)
      end
    end
  end

  private

  def order_details
    OrderDetail.purchased_active_reservations
      .merge(Reservation.relay_in_progress)
      .where('reserve_end_at < ?', Time.zone.now)
      .includes(:product)
      .readonly(false)
      .all
  end

  def auto_logout_time?(reserve_end_at, auto_logout_minutes)
    return false if reserve_end_at.nil? || auto_logout_minutes.nil?
    (reserve_end_at + auto_logout_minutes.minutes) < Time.zone.now
  end

  def complete_status
    @complete_status ||= OrderStatus.find_by_name!('Complete')
  end

  def complete_reservation(od)
    od.reservation.actual_end_at = Time.zone.now
    od.change_status!(complete_status)
    return unless od.price_policy
    costs = od.price_policy.calculate_cost_and_subsidy(od.reservation)
    return if costs.blank?
    od.actual_cost    = costs[:cost]
    od.actual_subsidy = costs[:subsidy]
    od.save!
    od.reservation.save!
  rescue => e
    STDERR.puts "Error on Order # #{od} - #{e}"
    raise ActiveRecord::Rollback
  end
end
