module TransactionSearch

  class BaseSearcher

    attr_reader :order_details

    def initialize(order_details)
      @order_details = order_details
    end

    def options
      raise NotImplementedError
    end

    def search(_params)
      raise NotImplementedError
    end

    # Include any optimizations to `order_details` such as `includes` or `preload`
    def optimized
      order_details
    end

  end

end
