module SplitAccounts

  # TODO: maybe refactor some of this into SplitSimulator
  # TODO: we can refactor this code to fewer lines and iterate fewer times
  class SplitOrderDetailSimulator

    SimulatedSplit = Struct.new(
      :split,
      :quantity,
      :actual_cost,
      :actual_subsidy,
      :estimated_cost,
      :estimated_subsidy
    )

    attr_accessor :order_detail, :account, :splits

    def initialize(order_detail)
      @order_detail = order_detail
      @account = order_detail.account
      @splits = account.splits
    end

    def simulated_order_details
      simulated_splits.map do |item|
        simulated_order_detail(item)
      end
    end

    def simulated_order_detail(item)
      clone = SplitOrderDetailDecorator.new(order_detail.dup)

      clone.account = item.split.subaccount
      clone.quantity = item.quantity
      clone.actual_cost = item.actual_cost
      clone.actual_subsidy = item.actual_subsidy
      clone.estimated_cost = item.estimated_cost
      clone.estimated_subsidy = item.estimated_subsidy

      clone
    end

    def simulated_splits
      items = splits.map { |split| simulated_split(split) }

      items = apply_remainder(items, :quantity)
      items = apply_remainder(items, :actual_cost)
      items = apply_remainder(items, :actual_subsidy)
      items = apply_remainder(items, :estimated_cost)
      items = apply_remainder(items, :estimated_subsidy)

      items
    end

    def simulated_split(split)
      item = SimulatedSplit.new(split)
      percent = split.percent

      item.quantity = floored_amount(percent, :quantity)
      item.actual_cost = floored_amount(percent, :actual_cost)
      item.actual_subsidy = floored_amount(percent, :actual_subsidy)
      item.estimated_cost = floored_amount(percent, :estimated_cost)
      item.estimated_subsidy = floored_amount(percent, :estimated_subsidy)

      item
    end

    def apply_remainder(items, attr)
      return items if order_detail.send(attr).blank?

      adjustment = order_detail.send(attr) - floored_total(items, attr)
      index = items.find_index { |item| item.split.extra_penny }
      items[index].send "#{attr}=", (items[index].send(attr) + adjustment)
      items
    end

    def floored_total(items, attr)
      items.reduce(BigDecimal("0")) { |sum, item| sum + item.send(attr) }
    end

    def floored_amount(percent, attr)
      return 0 if percent == 0 || order_detail.send(attr).blank?

      cents = (order_detail.send(attr) * 100) * (BigDecimal(percent) / 100)
      cents.floor.to_f / 100
    end

  end

end
