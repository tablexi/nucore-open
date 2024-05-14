# frozen_string_literal: true

module TransactionSearch

  class CrossCoreSearcher < BaseSearcher
    OPTIONS_MAP = {
      yes: true,
      no: false,
      both: nil,
    }.freeze

    def options
      OPTIONS_MAP.keys.map(&:to_s)
    end

    def search(params)
      return order_details if params.blank?

      params = params.first

      # Based on params, filter by cross_core_project_id present in order_detail.order
      if params == OPTIONS_MAP[:no].to_s
        order_details.joins(:order).where(orders: { cross_core_project_id: nil })
      elsif params == OPTIONS_MAP[:yes].to_s
        order_details.joins(:order).where(orders: { original_cross_core_order: false }).where.not(orders: { cross_core_project_id: nil })
      else
        order_details
      end
    end

    def label_method
      :capitalize
    end

    def value_method(option)
      OPTIONS_MAP[option.to_sym]
    end

    def label
      # TODO: Use translation
      "Only Cross-Core?"
    end

  end

end
