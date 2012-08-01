class JournalRow < ActiveRecord::Base
  belongs_to :journal
  belongs_to :order_detail

  validates_presence_of :journal_id, :amount
  validates_presence_of :account if SettingsHelper.feature_on? :expense_accounts
end