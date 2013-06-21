class Accessories::Scaling::Default
  def initialize(order_detail)
    @order_detail = order_detail
  end

  def default_quantity
    1
  end

  def updated_quantity
    @order_detail.quantity
  end
end
