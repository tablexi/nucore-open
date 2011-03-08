class CreditAccountTransaction < AccountTransaction
  validates_numericality_of :transaction_amount, :less_than_or_equal_to => 0
  validates_numericality_of :order_detail_id, :only_integer => true, :greater_than_or_equal_to => 1
end