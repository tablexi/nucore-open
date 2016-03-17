require "hash_helper"
module SplitAccounts
  module Reports
    class ExportRawTransformer
      include HashHelper
      include ActionView::Helpers::NumberHelper

      def transform(original_hash)
        insert_into_hash_after(original_hash, :actual_total, split_percentage: method(:split_percent))
      end

      private

      def split_percent(order_detail)
        number_with_precision(order_detail.split.percent, strip_insignificant_zeros: true) + "%" if order_detail.split
      end
    end
  end
end
