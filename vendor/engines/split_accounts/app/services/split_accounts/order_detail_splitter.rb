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

      apply_order_detail_remainders
      apply_reservation_remainders if split_reservations?

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
      split_order_detail.split = split
      split_order_detail.account = split.subaccount
      order_detail_attribute_splitter.split(order_detail, split_order_detail, split)
      build_split_reservation(split_order_detail, split) if split_reservations?

      # `dup` does not copy over ID. This assignment needs to happen after the
      # reservation is set, otherwise ActiveRecord will delete the original reservation.
      split_order_detail.id = order_detail.id

      split_order_detail
    end

    def split_reservations?
      @split_reservations.present?
    end

    def build_split_reservation(split_order_detail, split)
      return unless order_detail.reservation
      split_reservation = SplitReservationDecorator.new(order_detail.reservation.dup)
      reservation_attribute_splitter.split(order_detail.reservation, split_reservation, split)
      # Warning: if `id` is set on the order_detail when this assignment happens,
      # ActiveRecord will delete the original reservation. This was a change in
      # behavior between Rails 4.1 and 4.2.
      split_order_detail.reservation = split_reservation
    end

    def apply_order_detail_remainders
      applier = RemainderApplier.new(order_detail, split_order_details, splits)
      applier.apply_remainders(order_detail_attribute_splitter)
    end

    def apply_reservation_remainders
      return unless order_detail.reservation
      applier = RemainderApplier.new(order_detail.reservation, split_order_details.map(&:reservation), splits)
      applier.apply_remainders(reservation_attribute_splitter)
    end

  end

end
