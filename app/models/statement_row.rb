class StatementRow < ActiveRecord::Base
  belongs_to :statement
  belongs_to :order_detail

  validates_presence_of :order_detail_id, :statement_id

  def amount
    order_detail.total
  end
end
