class JournalRow < ActiveRecord::Base
  belongs_to :journal
  belongs_to :order_detail
  belongs_to :account_transaction

  validates_presence_of :journal_id, :fund, :dept, :account, :amount
end