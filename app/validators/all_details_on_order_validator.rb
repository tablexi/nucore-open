class AllDetailsOnOrderValidator

  cattr_accessor :order_detail_validator_class

  def self.build(order_detail_validator_class)
    Class.new(AllDetailsOnOrderValidator) do
      self.order_detail_validator_class = order_detail_validator_class
    end
  end

  def initialize(order)
    @order = order
  end

  def valid?
    # Use select instead of none? to make sure we loop over everything
    invalid_orders = @order.order_details.reject do |od|
      self.class.order_detail_validator_class.new(od).valid?
    end

    invalid_orders.none?
  end

  def error_message
    "Some products require notes"
  end

end
