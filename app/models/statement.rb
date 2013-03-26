class Statement < ActiveRecord::Base
  has_many :order_details, :inverse_of => :statement
  has_many :statement_rows, :dependent => :destroy
  belongs_to :account
  belongs_to :facility
  belongs_to :created_by_user, :class_name => 'User', :foreign_key => :created_by

  validates_numericality_of :account_id, :facility_id, :created_by, :only_integer => true

  default_scope :order => 'statements.created_at DESC'

  def account_balance_due (account)
    at = order_details.find(:first,
        :joins => "INNER JOIN statement_rows ON statement_rows.statement_id=statements.id",
        :conditions => ["order_details.reviewed_at <= ? AND order_details.account_id = ?", self.invoice_date, account.id],
        :select => 'SUM(statement_rows.amount) AS balance' )
    at.nil? ? 0 : at.balance.to_f
  end

  # Used in NU branch
  def first_order_detail_date
    min_order = order_details.min {|a,b| a.order.ordered_at <=> b.order.ordered_at}
    min_order.order.ordered_at
  end

  def total_cost
    statement_rows.inject(0) { |sum, row| sum += row.amount}
  end

  def invoice_number
    "#{account_id}-#{id}"
  end

  def reconciled?
    order_details.where('state <> ?', 'reconciled').empty?
  end

  def add_order_detail(order_detail)
    self.statement_rows << StatementRow.new(:amount => order_detail.total, :order_detail => order_detail)
    self.order_details << order_detail
  end
end
