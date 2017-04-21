module TimeData

  class Instrument

    def initialize(order_detail)
      @order_detail = order_detail
    end

    def time_data
      @order_detail.reservation
    end

  end

end
