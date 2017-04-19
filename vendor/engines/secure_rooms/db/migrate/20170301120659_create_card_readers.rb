class CreateCardReaders < ActiveRecord::Migration

  def change
    create_table :secure_rooms_card_readers do |t|
      t.references :product, null: false
      t.foreign_key :products

      t.string :card_reader_number
      t.string :control_device_number

      t.timestamps null: false
    end

    if NUCore::Database.oracle?
      add_index :secure_rooms_card_readers, :product_id, name: "index_card_readers_on_prod_id"
    else
      add_index :secure_rooms_card_readers, :product_id
    end
  end

end
