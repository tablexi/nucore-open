class StatementRow < ActiveRecord::Base

  belongs_to :statement
  belongs_to :order_detail

  validates_presence_of :order_detail_id, :statement_id

  before_destroy { @parent_statement = statement }
  after_destroy { @parent_statement.destroy if @parent_statement.statement_rows.empty? }

  def amount
    order_detail.total
  end

end
