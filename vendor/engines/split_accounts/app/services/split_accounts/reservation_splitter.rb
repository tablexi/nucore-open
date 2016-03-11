module SplitAccounts
  class ReservationSplitter
    attr_reader :reservation

    def initialize(reservation)
      @reservation = reservation
    end

    def self.splittable_attrs
      [
        :duration_mins,
        :actual_duration_mins,
      ]
    end

    def splittable_attrs
      self.class.splittable_attrs
    end

    def split
      results = OrderDetailSplitter.new(reservation.order_detail).split do |split_order_detail, split|
        split_reservation = SplitReservationDecorator.new(reservation.dup)
        split_order_detail.reservation = split_reservation

        split_attributes(split_reservation, split)
      end.map(&:reservation)
      results
    end

    def split_attributes(split_reservation, split)
      splittable_attrs.each do |attr|
        split_reservation.public_send "#{attr}=", floored_amount(split.percent, reservation.public_send(attr))
      end
    end

    def floored_amount(percent, value)
      return BigDecimal(0) if percent == 0 || value.blank?
      amount = BigDecimal(value) * BigDecimal(percent) / 100
      amount.floor(2)
    end
  end
end
