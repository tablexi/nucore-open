class OrderDetailJournalRemover
  def self.remove_from_journal(order_detail)
    OrderDetail.transaction do
      order_detail.journal_rows.each do |journal_row|
        journal_row.try(:destroy)
        order_detail.update_attributes!(journal_id: nil)
      end
    end
  end
end
