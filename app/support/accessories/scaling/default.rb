class Accessories::Scaling::Default
  attr_accessor :enabled

  def initialize(order_detail)
    @order_detail = order_detail
  end

  def update_quantity
    @order_detail.quantity ||= 1
  end

  def quantity_editable?
    true
  end

  def quantity_as_time?
    false
  end

  def enabled?
    !!@enabled
  end

  def assign_attributes(attrs)
    self.enabled = attrs.delete :enabled if attrs[:enabled]
    @order_detail.assign_attributes(attrs)
  end

  def to_s
    @order_detail.to_s
  end

  def to_param
    @order_detail.to_param
  end

  private

  def method_missing(method, *args)
    @order_detail.send(method, *args)
  end
end
