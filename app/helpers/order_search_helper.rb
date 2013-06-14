module OrderSearchHelper
  def order_result_link(order_detail)
    if can_manage_order_detail? order_detail
      path = edit_facility_order_path(order_detail.order.facility, order_detail.order)
    else
      path = order_path(order_detail.order)
    end
    link_to order_detail.order.id, path
  end

  def order_detail_result_link(order_detail)
    if can_manage_order_detail? order_detail
      path = edit_facility_order_order_detail_path(order_detail.order.facility, order_detail.order, order_detail)
    else
      path = order_order_detail_path(order_detail.order, order_detail)
    end
    link_to order_detail.id, path
  end

  private

  def can_manage_order_detail?(order_detail)
    ability = Ability.new(current_user, order_detail, controller)
    ability.can? :manage, order_detail
  end
end