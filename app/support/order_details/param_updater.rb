class OrderDetails::ParamUpdater
  def initialize(order_detail)
    @order_detail = order_detail
  end

  def assign_attributes(params)
    params ||= {}
    update_attributes(params.dup)
    assign_policy_and_prices
    @order_detail
  end

  private

  def update_attributes(params)
    reservation_attrs = params.delete :reservation
    @order_detail.assign_attributes(params)
    @order_detail.reservation.assign_times_from_params reservation_attrs if @order_detail.reservation && reservation_attrs
  end

  def assign_policy_and_prices
    @order_detail.assign_price_policy if @order_detail.complete?
    @order_detail.assign_estimated_price unless @order_detail.price_policy && @order_detail.actual_cost
  end
end
