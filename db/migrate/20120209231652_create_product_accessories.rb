class CreateProductAccessories < ActiveRecord::Migration
  def self.up
    create_table :product_accessories do |t|
      t.references  :product,       :null => false
      t.integer     :accessory_id,  :null => false
    end

    add_foreign_key :product_accessories, :products
    add_foreign_key :product_accessories, :products, :column => :accessory_id
  end

  def self.down
    drop_table :product_accessories
  end
end
