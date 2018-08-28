# frozen_string_literal: true

class AddAccountIdToJournalRows < ActiveRecord::Migration

  def change
    add_column :journal_rows, :account_id, :integer
    add_index :journal_rows, :account_id
  end

end
