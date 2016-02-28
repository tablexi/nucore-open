module SplitAccounts

  module Reports

    class Transformer

      attr_reader :order_details

      def initialize(order_details = [])
        @order_details = order_details
      end

      def perform
        order_details.map do |order_detail|
          # We will need to refactor the general_reports_controller_spec in
          # order to remove the `try` methods below.
          if order_detail.account.try(:splits).try(:present?)
            SplitAccounts::OrderDetailSplitter.new(order_detail).build_split_order_details
          else
            order_detail
          end
        end.flatten
      end

    end

  end

end
