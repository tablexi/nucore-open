class CreateOrderImports < ActiveRecord::Migration
  def self.up
    create_table :order_imports do |t|
      t.column :upload_file_id, :integer, :null => false
      t.column :error_file_id, :integer
      t.column :created_by, :integer, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :order_imports
  end
end
