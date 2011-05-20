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

    PriceGroupProduct.reset_column_information

    price_policies=PricePolicy.find(:all, :conditions => [ 'start_date <= ? AND restrict_purchase != 1', Time.zone.now ])

    price_policies.each do |pp|
      pgp=PriceGroupProduct.new(:price_group => pp.price_group)

      case pp
        when InstrumentPricePolicy
          pgp.product=pp.instrument
          pgp.reservation_window=pp.reservation_window
        when ServicePricePolicy
          pgp.product=pp.service
        when ItemPricePolicy
          pgp.product=pp.item
      end

      pgp.save!
    end

    price_policies=PricePolicy.find(:all, :conditions => 'restrict_purchase = 1')
    price_policies.each{|pp| pp.destroy }
  end

  
  def self.down
    drop_table :price_group_products
  end
end
