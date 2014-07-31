class DropAmountFromStatementRow < ActiveRecord::Migration
  def up
    remove_column :statement_rows, :amount
  end

  def down
    add_column :statement_rows, :amount, :decimal, precision: 10, scale: 2,
      null: false, after: :statement_id

    StatementRow.all.each do |statement_row|
      statement_row.update_attributes(amount: statement_row.order_detail.total)
    end
  end
end
