module SplitAccounts

  # When an order detail is tied to a split account, return a collection of
  # spoofed split order details. The split order details are read-only and
  # should never get persisted.
  class OrderDetailSplitter

    attr_accessor :order_detail, :account, :splits, :split_order_details

    def initialize(order_detail)
      @order_detail = order_detail
      @account = order_detail.account
      @splits = account.splits
      @split_order_details = []
    end

    def splittable_attrs
      [
        :quantity,
        :actual_cost,
        :actual_subsidy,
        :estimated_cost,
        :estimated_subsidy,
      ]
    end

    def build_split_order_details
      @split_order_details = splits.map { |split| build_split_order_detail(split) }
      apply_remainders
      split_order_details
    end

    def build_split_order_detail(split)
      split_order_detail = SplitOrderDetailDecorator.new(order_detail.dup)
      split_order_detail.id = order_detail.id
      split_order_detail.split = split
      split_order_detail.account = split.subaccount
      splittable_attrs.each do |attr|
        split_order_detail.send "#{attr}=", floored_amount(split.percent, order_detail.send(attr))
      end
      split_order_detail
    end

    def apply_remainders
      index = find_remainder_index
      splittable_attrs.each { |attr| apply_remainder(attr, index) }
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

    def floored_amount(percent, value)
      return BigDecimal(0) if percent == 0 || value.blank?
      amount = BigDecimal(value) * BigDecimal(percent) / 100
      amount.floor(2)
    end

  end

end
