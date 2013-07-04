class OrderDetails::PriceChecker
  include ActionView::Helpers::NumberHelper

  def initialize(order_detail)
    @order_detail = order_detail
  end

  def prices_from_params(params)
    updater = OrderDetails::ParamUpdater.new(@order_detail)
    updater.assign_attributes(params)

    fields = [:estimated_cost, :estimated_subsidy, :estimated_total,
              :actual_cost,    :actual_subsidy,    :actual_total]

    results = fields.collect { |f| [f, number_with_precision(@order_detail.send(f), :precision => 2)] }
    Hash[results]
  end

  private


end