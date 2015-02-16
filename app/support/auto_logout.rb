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
    od.reservation.actual_end_at = Time.zone.now
    od.change_status!(complete_status)
    return unless od.price_policy
    costs = od.price_policy.calculate_cost_and_subsidy(od.reservation)
    return if costs.blank?
    od.actual_cost    = costs[:cost]
    od.actual_subsidy = costs[:subsidy]
    od.save!
  rescue => e
    STDERR.puts "Error on Order # #{od} - #{e}"
    raise ActiveRecord::Rollback
  end
end
