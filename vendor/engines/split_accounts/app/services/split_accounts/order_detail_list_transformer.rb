module SplitAccounts

  class OrderDetailListTransformer

    attr_reader :order_details

    def initialize(order_details = [])
      @order_details = order_details
    end

    def perform
      order_details.each_with_object([]) do |order_detail, results|
        # We will need to refactor the general_reports_controller_spec in
        # order to remove the `try` methods below.
        if order_detail.account.try(:splits).try(:present?)
          results.concat SplitAccounts::OrderDetailSplitter.new(order_detail).build_split_order_details
        else
          results << order_detail
        end
      end
    end

  end

end
