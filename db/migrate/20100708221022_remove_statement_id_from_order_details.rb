class RemoveStatementIdFromOrderDetails < ActiveRecord::Migration
  def self.up
    remove_foreign_key :order_details, :statements
    remove_column :order_details, :statement_id
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
