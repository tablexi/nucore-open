module OrderSearchHelper
  def order_result_link(order_detail)
    # if can?
    path = edit_facility_order_path(order_detail.order.facility, order_detail.order)
    # else
    #   path = order_path(order_detail.order)
    link_to order_detail.order.id, path
  end

  def order_detail_result_link(order_detail)
    # if can?
    path = edit_facility_order_order_detail_path(order_detail.order.facility, order_detail.order, order_detail)
    # else
    #   path = order_order_detail_path(order_detail.order, order_detail)
    link_to order_detail.id, path
  end
end