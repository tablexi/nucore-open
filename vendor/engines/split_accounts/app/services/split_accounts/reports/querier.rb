module SplitAccounts

  module Reports

    class Querier < ::Reports::Querier

      def perform
        super.map do |order_detail|
          simulate_order_details(order_detail)
        end.flatten
      end

      def simulate_order_details(order_detail)
        if order_detail.account.is_a?(SplitAccounts::SplitAccount)
          simulate_split_order_details(order_detail)
        else
          order_detail
        end
      end

      def simulate_split_order_details(order_detail)
        SplitAccounts::SplitOrderDetailSimulator.new(order_detail).simulated_order_details
      end

    end

  end

end
