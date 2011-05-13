class Statement < ActiveRecord::Base
  has_many :order_details
  has_many :statement_rows, :dependent => :destroy
  belongs_to :account
  belongs_to :facility

  validates_numericality_of :account_id, :facility_id, :created_by, :only_integer => true

  default_scope :order => 'statements.created_at DESC'

  def account_balance_due (account)
    at = order_details.find(:first,
        :joins => "INNER JOIN statement_rows ON statement_rows.statement_id=statements.id",
        :conditions => ["order_details.reviewed_at <= ? AND order_details.account_id = ?", self.invoice_date, account.id],
        :select => 'SUM(statement_rows.amount) AS balance' )
    at.nil? ? 0 : at.balance.to_f
  end
end
