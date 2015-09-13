module OrdersHelper
  def display_cost_prefix_for_order(order)
    case
    when order.order_details.with_actual_costs.present?
      :actual
    when order.order_details.with_estimated_costs.present?
      :estimated
    else
      :unassigned
    end
  end

  def display_cost_prefix_for_order_detail(order_detail)
    case
    when order_detail.actual_cost
      :actual
    when order_detail.estimated_cost
      :estimated
    else
      :unassigned
    end
  end
end
