class JournalRowConverter

  # Returns an array of generated journal_rows given a single order_detail.
  def self.from_order_detail(order_detail, journal = nil)
    [{
      account: order_detail.product.account,
      amount: order_detail.total,
      description: order_detail.long_description,
      order_detail_id: order_detail.id,
      journal_id: journal.try(:id),
    }]
  end

  # Returns an array of generated journal_rows given a single product.
  def self.from_product(product, total, journal = nil)
    [{
      account: product.facility_account.revenue_account,
      amount: total * -1,
      description: product.to_s,
      journal_id: journal.try(:id),
    }]
  end

end
