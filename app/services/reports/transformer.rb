module Reports

  # This is the default placeholder transformer which does nothing.
  # Modify settings to use a different transformer to modify/tranform order
  # detail results before sending them to get reported.
  class Transformer

    attr_reader :order_details

    def initialize(order_details)
      @order_details = order_details
    end

    def perform
      order_details
    end

  end

end
