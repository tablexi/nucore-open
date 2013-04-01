module OrdersHelper
  def order_estimated_or_actual_text(order)
    best_status = order.order_details.to_a.find { |od| od.display_cost_class != 'unassigned' }
    best_status ? best_status.display_cost_class.humanize : ''
  end
end