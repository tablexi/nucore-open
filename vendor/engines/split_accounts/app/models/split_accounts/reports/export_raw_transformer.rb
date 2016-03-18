module SplitAccounts
  module Reports
    class ExportRawTransformer
      include ActionView::Helpers::NumberHelper

      def transform(original_hash)
        insert_into_hash_after(original_hash, :actual_total, split_percent: method(:split_percent))
      end

      private

      def split_percent(order_detail)
        if order_detail.respond_to?(:split) && order_detail.split
          number_with_precision(order_detail.split.percent, strip_insignificant_zeros: true) + "%"
        end
      end

      def insert_into_hash_after(original_hash, after_column, additions)
        original_hash.each_with_object({}) do |(k, v), new_hash|
          new_hash[k] = v
          new_hash.merge!(additions) if k == after_column
        end
      end
    end
  end
end
