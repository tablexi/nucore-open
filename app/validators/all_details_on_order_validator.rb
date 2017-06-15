class AllDetailsOnOrderValidator

  cattr_accessor :order_detail_validator_class

  # Build a validator that will take an Order in its constructor and validate each
  # child order detail using the order_detail_validator_class.
  #
  # Example:
  # validator = AllDetailsOnOrder.build(NotePresenceValidator)
  # validator.new(order).valid?
  #
  # This will run NotePresenceValidator.new(order_detail).valid? for each
  # element of @order.order_details
  def self.build(order_detail_validator_class)
    Class.new(AllDetailsOnOrderValidator) do
      self.order_detail_validator_class = order_detail_validator_class
    end
  end

  # This class should only be initialized through the `.build` method
  def initialize(order)
    raise "Should not be initialized directly. Use the `.build` factory method instead" unless order_detail_validator_class
    @order = order
  end

  def valid?
    # Use select instead of none? to make sure we loop over everything
    invalid_orders = @order.order_details.reject do |od|
      order_detail_validator_class.new(od).valid?
    end

    invalid_orders.none?
  end

  def error_message
    I18n.t(order_detail_validator_class.name.underscore, scope: "validators.all_details_on_order_validator")
  end

end
