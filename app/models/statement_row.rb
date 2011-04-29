class StatementRow < ActiveRecord::Base
  belongs_to :account
  belongs_to :statement

  validates_presence_of :account_id, :statement_id
  validates_numericality_of :amount, :greater_than_or_equal_to => 0
end