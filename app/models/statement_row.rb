class StatementRow < ActiveRecord::Base
  belongs_to :statement
  belongs_to :order_detail

  validates_presence_of :order_detail_id, :statement_id
  validates_numericality_of :amount, :greater_than_or_equal_to => 0
end