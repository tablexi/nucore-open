module SplitAccounts

  # This decorator permits us to assign decimals to quantity (rather than ints)
  # when dealing with simulated split order details.
  class SplitOrderDetailDecorator < SimpleDelegator

    attr_accessor :quantity_override, :split

    def quantity
      quantity_override || __getobj__.quantity
    end

    def quantity=(value)
      @quantity_override = BigDecimal("#{value}")
    end

    # Let it pretend to be a real OrderDetail
    def is_a?(klass)
      __getobj__.class.object_id == klass.object_id
    end

    def self.primary_key
      __getobj__.class.primary_key
    end

  end

end
