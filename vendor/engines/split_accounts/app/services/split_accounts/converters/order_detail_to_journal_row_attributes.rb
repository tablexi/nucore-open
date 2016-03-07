module SplitAccounts
  module Converters
    class OrderDetailToJournalRowAttributes

      SplitAmount = Struct.new(:split, :amount)

      attr_accessor :journal, :order_detail, :total, :splits

      def initialize(journal, order_detail, options = {})
        @journal = journal
        @order_detail = order_detail
        @total = options[:total] || order_detail.total
        @splits = options[:splits] || order_detail.account.splits
      end

      def convert
        build_split_amounts.map do |split_amount|
          factory = ::Converters::ConverterFactory.new(account: split_amount.split.subaccount)
          klass = factory.for("order_detail_to_journal_rows")
          klass.new(journal, order_detail, total: split_amount.amount).convert
        end.flatten
      end

      def build_split_amounts
        split_amounts = splits.map { |split| build_split_amount(split) }
        apply_remainder(split_amounts)
      end

      def build_split_amount(split)
        SplitAmount.new(split, floored_amount(split.percent))
      end

      def apply_remainder(split_amounts)
        adjustment = total - floored_total(split_amounts)
        index = split_amounts.find_index { |split_amount| split_amount.split.extra_penny }
        split_amounts[index].amount += adjustment
        split_amounts
      end

      def floored_total(split_amounts)
        split_amounts.reduce(0) { |sum, split_amount| sum + split_amount.amount }
      end

      def floored_amount(percent)
        return 0 if percent == 0
        cents = (total * 100) * (BigDecimal(percent) / 100)
        cents.floor.to_f / 100
      end

    end
  end
end
