class CreateCardReaderAndControlDevice < ActiveRecord::Migration

  def change
    create_table :card_readers do |t|
      t.references :control_device, null: false

      t.boolean :entrance, null: false

      t.timestamps null: false
    end

    create_table :control_devices do |t|
      t.references :secure_room, null: false

      t.timestamps null: false
    end
  end

end
