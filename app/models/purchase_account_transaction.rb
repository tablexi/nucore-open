class PurchaseAccountTransaction < AccountTransaction
  validates_numericality_of :transaction_amount, :greater_than_or_equal_to => 0
  validates_numericality_of :order_detail_id, :only_integer => true, :greater_than_or_equal_to => 1
  
  def set_disputed
    self.finalized_at  = nil
    self.is_in_dispute = true
  end

  def move_to_new_account!(new_account, args = {})
    total_txn_amount  = transaction_amount_with_credits
    if statement_id && statement.invoice_date > Time.zone.now
    	# credit the account (on same statement)
    	self.finalized_at = statement_invoice_date
    	txn_credit = CreditAccountTransaction.create!(
    	    :finalized_at       => finalized_at,
    	    :statement_id       => statement_id,
    	    :account_id         => account_id,
    	    :facility_id        => facility_id,
          :description        => "Moved Order ##{order_detail} to #{new_account.account_number}",
          :transaction_amount => total_txn_amount * -1,
          :order_detail_id    => order_detail_id,
          :created_by         => args[:created_by],
          :is_in_dispute      => false )
    else
    	# credit the account (new statement)
    	self.statement_id = nil
    	txn_credit = CreditAccountTransaction.create!(
    	    :account_id         => account_id,
    	    :facility_id        => facility_id,
          :description        => "Moved Order ##{order_detail} to #{new_account.account_number}",
          :transaction_amount => total_txn_amount * -1,
          :order_detail_id    => order_detail_id,
          :created_by         => args[:created_by],
          :is_in_dispute      => false )
    end

		# create the move
    txn_purchase = PurchaseAccountTransaction.create!(
        :account_id         => new_account.id,
  	    :facility_id        => facility_id,
        :description        => "Order ##{order_detail} moved from #{account.account_number}",
        :transaction_amount => total_txn_amount,
        :order_detail_id    => order_detail_id,
        :created_by         => args[:created_by],
        :is_in_dispute      => false )
    self.save!
  end
  
  def resolve_dispute_with_credit!(credit_amount, args = {})
    txn_credit = CreditAccountTransaction.create!(
      :account_id          => account_id,
      :facility_id         => facility_id,
      :order_detail_id     => order_detail_id,
      :description         => "Dispute credit for Order ##{order_detail}",
      :transaction_amount  => @order_detail.dispute_resolved_credit.to_f * -1,
      :created_by          => args[:created_by],
      :is_in_dispute       => false
    )
    if statement_id && statement.invoice_date > Time.zone.now
      txn_credit.finalized_at = statement.invoice_date
      txn_credit.statement_id = statement_id
    end
    txn_credit.save!
    self.is_in_dispute = false
    self.save!
  end
  
  def transaction_amount_with_credits
    self.account.account_transactions.find(:first,
	                                         :conditions => {:order_detail_id => self.order_detail_id},
	                                         :select => "SUM(transaction_amount) AS balance" ).balance
  end
end