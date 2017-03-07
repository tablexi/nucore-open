class CreateCardReaderAndControlDevice < ActiveRecord::Migration

  def change
    create_table :secure_rooms_control_devices do |t|
      t.references :product, null: false
      t.foreign_key :products

      t.timestamps null: false
    end

    create_table :secure_rooms_card_readers do |t|
      t.references :secure_rooms_control_device, null: false
      t.foreign_key :secure_rooms_control_devices

      t.timestamps null: false
    end
  end

end
