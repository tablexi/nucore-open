# frozen_string_literal: true

module PricePolicies

  module Usage

    extend ActiveSupport::Concern

    included do
      validates :usage_rate, presence: true, unless: :restrict_purchase?
      validates :usage_rate, :usage_subsidy, :minimum_cost, numericality: { allow_blank: true, greater_than_or_equal_to: 0 }
    end

    def has_rate?
      usage_rate && usage_rate > -1
    end

    def has_minimum_cost?
      minimum_cost && minimum_cost > -1
    end

    def usage_rate=(hourly_rate)
      super
      self[:usage_rate] /= 60.0 if self[:usage_rate].respond_to? :/
    end

    def usage_subsidy=(hourly_subsidy)
      super
      self[:usage_subsidy] /= 60.0 if self[:usage_subsidy].respond_to? :/
    end

    def hourly_usage_rate
      usage_rate.try :*, 60
    end

    def hourly_usage_subsidy
      usage_subsidy.try :*, 60
    end

    def subsidized_hourly_usage_cost
      hourly_usage_rate - hourly_usage_subsidy
    end

    def minimum_cost_subsidy
      return unless has_minimum_cost?
      minimum_cost * subsidy_ratio
    end

    def subsidized_minimum_cost
      return unless has_minimum_cost?
      minimum_cost - minimum_cost_subsidy
    end

    private

    def subsidy_ratio
      return 0 if usage_rate.zero?
      usage_subsidy / usage_rate
    end

    def rate_field
      :usage_rate
    end

    def subsidy_field
      :usage_subsidy
    end

  end

end
