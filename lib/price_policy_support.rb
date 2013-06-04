module PricePolicySupport
  # TODO Refactor out of InstrumentPricePolicy into here
  module ReservationPolicy
  end

  module QuantityPolicy
    extend ActiveSupport::Concern
    included do
      validates_numericality_of :unit_cost, :unless => :restrict_purchase
      validate :subsidy_more_than_cost?, :unless => lambda { |pp| pp.unit_cost.nil? || pp.unit_subsidy.nil? }
      before_save { |o| o.unit_subsidy = 0 if o.unit_subsidy.nil? && !o.unit_cost.nil? }
  	end


    def subsidy_more_than_cost?
      errors.add("unit_subsidy", "cannot be greater than the Unit cost") if (unit_subsidy > unit_cost)
    end

    def has_subsidy?
      unit_subsidy && unit_subsidy > 0
    end

    def calculate_cost_and_subsidy_from_order_detail(order_detail)
      calculate_cost_and_subsidy(order_detail.quantity)
    end

    def calculate_cost_and_subsidy (qty = 1)
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
  end
end
