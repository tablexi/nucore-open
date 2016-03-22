module SplitAccounts

  class ReservationSplitter

    attr_reader :reservation

    def initialize(reservation)
      @reservation = reservation
    end

    def split
      splitter = OrderDetailSplitter.new(reservation.order_detail, split_reservations: true)
      splitter.split.map(&:reservation)
    end

  end

end
