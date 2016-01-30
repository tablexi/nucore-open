module Converters
  class OrderDetailToJournalRows

    attr_accessor :journal, :order_detail, :total

    def initialize(journal, order_detail, options = {})
      @journal = journal
      @order_detail = order_detail
      @total = options[:total] || order_detail.total
    end

    def to_a
      [{
        account: order_detail.product.account,
        amount: total,
        description: order_detail.long_description,
        order_detail_id: order_detail.id,
        journal_id: journal.try(:id),
      }]
    end

  end
end
