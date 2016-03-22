class OrderDetails::PriceChecker

  include ActionView::Helpers::NumberHelper

  def initialize(order_detail)
    @order_detail = order_detail
  end

  def prices_from_params(params)
    updater = OrderDetails::ParamUpdater.new(@order_detail)
    updater.assign_attributes(params)
    @order_detail.assign_price_policy(@order_detail.fulfilled_at || Time.zone.now)

    fields = [:estimated_cost, :estimated_subsidy, :estimated_total,
              :actual_cost,    :actual_subsidy,    :actual_total]

    results = fields.collect { |f| [f, number_with_precision(@order_detail.send(f), precision: 2)] }

    results << [:price_group, price_group_name]

    Hash[results]
  end

  private

  def price_group_name
    @order_detail.price_group.try(:name) || @order_detail.estimated_price_group.try(:name)
  end

end
