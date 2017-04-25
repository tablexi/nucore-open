module TimeData

  class SecureRoomData

    def initialize(order_detail)
      @order_detail = order_detail
    end

    def time_data
      @order_detail.occupancy
    end

  end

end
