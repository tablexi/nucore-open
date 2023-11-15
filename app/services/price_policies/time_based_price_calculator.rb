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

      if product.is_a?(Instrument) && product.duration_pricing_mode? && price_policy.duration_rates.present?
        duration_pricing_cost_and_subsidy(duration_mins)
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

    def duration_pricing_cost_and_subsidy(duration_mins)
      duration_in_hours = duration_mins / 60.0

      result = build_intervals.reduce({ time_left: duration_in_hours, cost: 0, subsidy: 0 }) do |acc, interval_data|
        time_left = acc[:time_left]

        interval_length = interval_data[:interval_end] - interval_data[:interval_start]

        time_to_charge = [time_left, interval_length].min

        acc[:time_left] -= time_to_charge
        acc[:cost] += interval_data[:rate] ? interval_data[:rate] * time_to_charge : 0
        acc[:subsidy] += interval_data[:subsidy] ? interval_data[:subsidy] * time_to_charge : 0

        acc
      end

      { cost: result[:cost], subsidy: result[:subsidy] }
    end

    def build_intervals
      sorted_duration_rates = price_policy.duration_rates.sort_by { |dr| dr.min_duration_hours || 1_000 }
      lower_intervals = sorted_duration_rates.dup
      higher_intervals = sorted_duration_rates.dup

      if sorted_duration_rates.first.min_duration_hours > 0
        lower_intervals.prepend nil
      else
        higher_intervals.shift
      end

      lower_intervals.zip(higher_intervals).map do |lower, higher|
        hourly_rate = lower ? lower.rate : usage_rate * 60
        hourly_subsidy = lower ? lower.subsidy : usage_subsidy * 60
        interval_start = lower&.min_duration_hours || 0
        interval_end = higher&.min_duration_hours || Float::INFINITY

        { interval_start: , interval_end:, rate: hourly_rate, subsidy: hourly_subsidy }
      end
    end

  end

end
