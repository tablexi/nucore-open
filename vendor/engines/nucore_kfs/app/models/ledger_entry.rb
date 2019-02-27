class LedgerEntry < ActiveRecord::Base
  belongs_to :journal_row

  enum kfs_status: { pending: 0, failure: 1, success: 2 }
end