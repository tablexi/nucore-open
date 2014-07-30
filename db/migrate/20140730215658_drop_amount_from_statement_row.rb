class DropAmountFromStatementRow < ActiveRecord::Migration
  def up
    remove_column :statement_rows, :amount
  end

  def down
    raise ActiveRecord::IrreversibleMigration
    add_column :statement_rows, :amount # TODO repopulate from OrderDetail#total
  end
end
