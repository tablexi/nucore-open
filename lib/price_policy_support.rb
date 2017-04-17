module PricePolicySupport

  # TODO: Refactor out of InstrumentPricePolicy into here
  module ReservationPolicy
  end

  module QuantityPolicy

    extend ActiveSupport::Concern

    def calculate_cost_and_subsidy_from_order_detail(order_detail)
      calculate_cost_and_subsidy(order_detail.quantity)
    end

    def calculate_cost_and_subsidy(qty = 1)
      estimate_cost_and_subsidy(qty)
    end

    def estimate_cost_and_subsidy_from_order_detail(order_detail)
      estimate_cost_and_subsidy(order_detail.quantity)
    end

    def estimate_cost_and_subsidy(qty = 1)
      return nil if restrict_purchase?
      costs = {}
      costs[:cost]    = unit_cost * qty
      costs[:subsidy] = unit_subsidy * qty
      costs
    end

    def unit_total
      unit_cost - unit_subsidy
    end

    private

    def rate_field
      :unit_cost
    end

    def subsidy_field
      :unit_subsidy
    end

  end

end
