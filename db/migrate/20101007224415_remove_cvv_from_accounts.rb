# frozen_string_literal: true

class RemoveCvvFromAccounts < ActiveRecord::Migration

  def self.up
    remove_column :accounts, :cvv
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end

end
