class CreatePriceGroupProducts < ActiveRecord::Migration
  def self.up

    create_table :price_group_products do |t|
      t.integer :price_group_id, :null => false
      t.integer :product_id, :null => false
      t.integer :reservation_window
      t.timestamps
    end

    add_index :price_group_products, :price_group_id
    add_index :price_group_products, :product_id
  end

  
  def self.down
    drop_table :price_group_products
  end
end
