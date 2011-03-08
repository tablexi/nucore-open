class Statement < ActiveRecord::Base
  has_many :accounts, :through => :account_transactions
  has_many :account_transactions
  belongs_to :facility

  validates_numericality_of :facility_id, :created_by, :only_integer => true

  default_scope :order => 'statements.created_at DESC'
  named_scope :final_for_facility, lambda { |facility| { :conditions => ['statements.facility_id = ? AND invoice_date <= ?', facility.id, Time.zone.now]}}

  def account_balance_due (account)
    at = account.account_transactions.find(:first,
        :conditions => ["finalized_at <= ?",self.invoice_date],
        :select => 'SUM(transaction_amount) AS balance' )
    at.nil? ? 0 : at.balance.to_f
  end
end
