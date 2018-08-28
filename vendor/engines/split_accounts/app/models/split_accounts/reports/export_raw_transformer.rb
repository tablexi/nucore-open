# frozen_string_literal: true

require "hash_helper"
module SplitAccounts

  module Reports

    class ExportRawTransformer

      include HashHelper
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

    end

  end

end
