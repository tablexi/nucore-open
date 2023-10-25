# frozen_string_literal: true

module PricePolicies

  class TimeBasedPriceCalculator

    attr_reader :price_policy

    delegate :usage_rate, :usage_subsidy, :minimum_cost, :minimum_cost_subsidy,
             :product, to: :price_policy

    def initialize(price_policy)
      @price_policy = price_policy
    end

    def calculate(start_at, end_at)
      return if start_at > end_at
      duration_mins = TimeRange.new(start_at, end_at).duration_mins

      if product.is_a?(Instrument) && product.duration_pricing_mode? && product.duration_rates.present?
        # Should return something for subsidy as well?
        duration_pricing_cost(duration_mins)
      else
        discount_multiplier = calculate_discount(start_at, end_at)
        cost_and_subsidy(duration_mins, discount_multiplier)
      end
    end

    def calculate_discount(start_at, end_at)
      discount = product.schedule_rules.to_a.sum do |sr|
        sr.discount_for(start_at, end_at, price_policy.price_group)
      end

      1 - (discount / 100)
    end

    private

    def cost_and_subsidy(duration_mins, discount_multiplier)
      costs = { cost: duration_mins * usage_rate * discount_multiplier }

      if costs[:cost] < minimum_cost.to_f
        { cost: minimum_cost, subsidy: minimum_cost_subsidy }
      else
        costs.merge(subsidy: duration_mins * usage_subsidy * discount_multiplier)
      end
    end

    def duration_pricing_cost(duration_mins)
      duration_in_hours = duration_mins.to_f / 60

      # 3 cases for interval_data:
      # interval_data = [nil, { min_duration: 5, rate: 8 }]
      # interval_data = [{ min_duration: 0, rate: 10 }, { min_duration: 5, rate: 8 }]
      # interval_data = [{ min_duration: 0, rate: 10 }, nil]
      result = build_intervals.reduce({ time_left: duration_in_hours, cost: 0 }) do |acc, interval_data|
        time_left = acc[:time_left]

        interval_data_start = interval_data.first
        interval_data_end = interval_data.last

        hourly_rate = interval_data_start ? interval_data_start.rate : usage_rate * 60

        interval_start = interval_data_start&.min_duration || 0
        interval_end = interval_data_end&.min_duration || Float::INFINITY

        interval_length = interval_end - interval_start

        time_to_charge = [time_left, interval_length].min

        acc[:time_left] -= time_to_charge
        acc[:cost] += hourly_rate * time_to_charge

        acc
      end

      { cost: result[:cost] }
    end

    def build_intervals
      sorted_duration_rates = product.duration_rates.sort_by { |dr| dr.min_duration || 1_000 }
      lower_intervals = sorted_duration_rates.dup
      higher_intervals = sorted_duration_rates.dup

      if sorted_duration_rates.first.min_duration > 0
        lower_intervals.prepend nil
      else
        higher_intervals.shift
      end

      lower_intervals.zip(higher_intervals)
    end
  end
end
