# frozen_string_literal: true

module TransactionSearch

  class CrossCoreSearcher < BaseSearcher
    def options
      ["yes", "no", "both"]
    end

    def search(params)
      return order_details if params.blank?

      params = params.first

      # Based on params, filter by cross_core_project_id present in order_detail.order
      if params == "no"
        order_details.joins(:order).where(orders: { cross_core_project_id: nil })
      elsif params == "yes"
        order_details.joins(:order).where(orders: { original_cross_core_order: false }).where.not(orders: { cross_core_project_id: nil })
      else
        order_details
      end
    end

    def label_method
      :capitalize
    end

    def label
      # TODO: Use translation
      "Only Cross-Core?"
    end

  end

end
