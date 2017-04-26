module PricePolicies

  class TimeBasedPriceCalculator

    attr_reader :price_policy

    delegate :usage_rate, :usage_subsidy, :minimum_cost, :minimum_cost_subsidy,
      :product, to: :price_policy

    def initialize(price_policy)
      @price_policy = price_policy
    end

    def calculate(start_at, end_at)
      duration_mins = TimeRange.new(start_at, end_at).duration_mins
      discount = calculate_discount(start_at, end_at)
      cost_and_subsidy(duration_mins, discount)
    end

    # TODO: Make private
    def calculate_discount(start_at, end_at)
      discount = product.schedule_rules.to_a.sum do |sr|
        sr.discount_for(start_at, end_at)
      end

      1 - (discount / 100)
    end

    private

    def cost_and_subsidy(duration_mins, discount)
      costs = { cost: duration_mins * usage_rate * discount }

      if costs[:cost] < minimum_cost.to_f
        { cost: minimum_cost, subsidy: minimum_cost_subsidy }
      else
        costs.merge(subsidy: duration_mins * usage_subsidy * discount)
      end
    end

  end

end
