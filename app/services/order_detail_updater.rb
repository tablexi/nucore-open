module NUCore

  class QuantityUpdateChangeException < StandardError
  end

end

class OrderDetailUpdater

  attr_reader :order, :params

  def initialize(order, params)
    @order = order
    @params = params
    @initial_quantities = quantities
  end

  def quantities_changed?
    @quantities_changed
  end

  def update
    update_result = order.update_details(params)
    @quantities_changed = (@initial_quantities != quantities)
    update_result
  end

  def update!
    update || raise(NUCore::QuantityUpdateChangeException)
  end

  private

  def quantities
    order.order_details.order("order_details.id").pluck(:quantity)
  end

end
