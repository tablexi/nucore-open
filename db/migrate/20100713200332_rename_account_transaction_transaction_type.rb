# frozen_string_literal: true

class RenameAccountTransactionTransactionType < ActiveRecord::Migration

  def self.up
    rename_column :account_transactions, :transaction_type, :type
  end

  def self.down
    rename_column :account_transactions, :type, :transaction_type
  end

end
