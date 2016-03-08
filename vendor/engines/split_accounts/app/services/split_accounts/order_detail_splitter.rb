module SplitAccounts

  # When an order detail is tied to a split account, return a collection of
  # spoofed split order details. The split order details are read-only and
  # should never get persisted.
  class OrderDetailSplitter

    attr_accessor :order_detail, :account, :splits, :split_order_details

    def initialize(order_detail, split_reservations: false)
      @order_detail = order_detail
      @account = order_detail.account
      @splits = account.splits
      @split_order_details = []
      @split_reservations = split_reservations
    end

    def split
      @split_order_details = splits.map { |split| build_split_order_detail(split) }
      apply_remainders
      split_order_details
    end

    private

    def order_detail_attribute_splitter
      AttributeSplitter.new(
        :quantity,
        :actual_cost,
        :actual_subsidy,
        :estimated_cost,
        :estimated_subsidy,
      )
    end

    def reservation_attribute_splitter
      AttributeSplitter.new(
        :duration_mins,
        :actual_duration_mins,
        :quantity,
      )
    end

    def build_split_order_detail(split)
      split_order_detail = SplitOrderDetailDecorator.new(order_detail.dup)
      split_order_detail.id = order_detail.id # dup does not copy over IDs
      split_order_detail.split = split
      split_order_detail.account = split.subaccount
      order_detail_attribute_splitter.split(order_detail, split_order_detail, split)

      build_split_reservation(split_order_detail, split) if split_reservations?

      split_order_detail
    end

    def split_reservations?
      @split_reservations.present?
    end

    def build_split_reservation(split_order_detail, split)
      split_reservation = SplitReservationDecorator.new(order_detail.reservation.dup)
      reservation_attribute_splitter.split(order_detail.reservation, split_reservation, split)
      split_order_detail.reservation = split_reservation
    end

    def apply_remainders
      index = find_remainder_index
      order_detail_attribute_splitter.splittable_attributes.each { |attr| apply_remainder(attr, index) }
    end

    def apply_remainder(attr, index)
      return if order_detail.send(attr).blank?
      adjustment = order_detail.send(attr) - floored_total(split_order_details, attr)
      new_value = split_order_details[index].send(attr) + adjustment
      split_order_details[index].send "#{attr}=", new_value
    end

    def find_remainder_index
      split_order_details.find_index { |item| item.split.extra_penny? }
    end

    def floored_total(items, attr)
      items.reduce(BigDecimal(0)) { |sum, item| sum + item.send(attr) }
    end

  end

end
