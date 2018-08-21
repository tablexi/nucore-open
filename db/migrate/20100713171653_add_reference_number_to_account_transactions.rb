# frozen_string_literal: true

class AddReferenceNumberToAccountTransactions < ActiveRecord::Migration

  def self.up
    add_column :account_transactions, :reference, :string, limit: 50, null: true
  end

  def self.down
    remove_column :account_transactions, :reference
  end

end
