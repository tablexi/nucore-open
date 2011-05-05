class CreateStatementRows < ActiveRecord::Migration
  def self.up
    create_table :statement_rows do |t|
      t.column :statement_id, :integer, :null => false
      t.column :order_detail_id, :integer, :null => false
      t.columm :description, :string, :limit => 250
      t.column :amount, :decimal, :precision => 10, :scale => 2, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :statement_rows
  end
end
