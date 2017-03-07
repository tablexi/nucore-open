class CreateCardReaderAndControlDevice < ActiveRecord::Migration

  def change
    ActiveRecord::Base.transaction do
      create_table :control_devices do |t|
        t.references :product, null: false
        t.foreign_key :products

        t.timestamps null: false
      end

      create_table :card_readers do |t|
        t.references :control_device, null: false
        t.foreign_key :control_devices

        t.timestamps null: false
      end
    end
  end

end
