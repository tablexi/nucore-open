class JournalRow < ActiveRecord::Base
  belongs_to :journal
  belongs_to :order_detail

  validates_presence_of :journal_id, :account, :amount
end