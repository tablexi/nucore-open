class PaymentAccountTransaction < AccountTransaction
  belongs_to :journal

  validates_presence_of :finalized_at, :reference
  validates_numericality_of :transaction_amount, :less_than => 0

  def for_nufs_account?
    return true if account_id.nil?
    account.is_a?(NufsAccount)
  end
end