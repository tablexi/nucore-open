class OrderDetails::ParamUpdater
  def initialize(order_detail, options = {})
    @order_detail = order_detail
    @editing_user = options[:user]
    @options = options
  end

  def assign_attributes(params)
    params = params.try(:dup) || {}
    assign_self_and_reservation_attributes(params)
    assign_policy_and_prices
    @order_detail
  end

  def update_attributes(params)
    params = params.try(:dup) || {}

    # Assign all the attributes first, and then update the order status.
    # We need to go through update_order_status! so we can cancel the reservation
    # when necessary
    order_status_id = params.delete :order_status_id

    assign_attributes(params)

    if order_status_id && order_status_id.to_i != @order_detail.order_status_id
      change_order_status(order_status_id, @options[:cancel_fee])
    else
      @order_detail.save
    end
  end

  private

  def assign_self_and_reservation_attributes(params)
    reservation_attrs = params.delete :reservation
    @order_detail.assign_attributes(params)
    @order_detail.reservation.assign_times_from_params reservation_attrs if @order_detail.reservation && reservation_attrs
  end

  def assign_policy_and_prices
    @order_detail.assign_price_policy if @order_detail.complete?
    @order_detail.assign_estimated_price unless @order_detail.price_policy && @order_detail.actual_cost
  end

  def change_order_status(order_status_id, apply_cancel_fee)
    begin
      @order_detail.update_order_status! @editing_user,
            OrderStatus.find(order_status_id),
            :admin => true,
            :apply_cancel_fee => apply_cancel_fee
      true
    rescue StandardError => e
      # returns nil
    end
  end
end
