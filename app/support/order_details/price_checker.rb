class OrderDetails::PriceChecker
  include ActionView::Helpers::NumberHelper

  def initialize(order_detail)
    @order_detail = order_detail
  end

  def prices_from_params(params)
    update_attributes(params.dup)

    assign_policy_and_prices

    fields = [:estimated_cost, :estimated_subsidy, :estimated_total,
              :actual_cost,    :actual_subsidy,    :actual_total]

    results = fields.collect { |f| [f, number_with_precision(@order_detail.send(f), :precision => 2)] }
    Hash[results]
  end

  private

  def update_attributes(params)
    reservation_attrs = params.delete :reservation
    @order_detail.assign_attributes(params)
    @order_detail.reservation.assign_times_from_params reservation_attrs if @order_detail.reservation
  end

  def assign_policy_and_prices
    @order_detail.assign_price_policy
    if @order_detail.complete?
      @order_detail.assign_actual_price(@order_detail.fulfilled_at)
    else
      @order_detail.assign_estimated_price
    end
  end
end