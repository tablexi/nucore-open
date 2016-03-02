module SplitAccounts

  module Reports

    class Transformer

      attr_reader :order_details

      def initialize(order_details = [])
        @order_details = order_details
      end

      def perform
        order_details.map do |order_detail|
          if order_detail.account.splits.present?
            SplitAccounts::OrderDetailSplitter.new(order_detail).build_split_order_details
          else
            order_detail
          end
        end.flatten
      end

    end

  end

end
