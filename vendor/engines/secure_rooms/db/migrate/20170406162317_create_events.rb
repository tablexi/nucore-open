class CreateEvents < ActiveRecord::Migration

  def change
    create_table :secure_rooms_events do |t|
      # As of this migration, it hasn't been determined if these are required
      t.references :card_reader
      t.references :product
      t.references :user

      t.datetime :occurred_at
      t.string :outcome

      t.timestamps null: false
    end

    add_index :secure_rooms_events, :user_id
    add_index :secure_rooms_events, :product_id
    add_index :secure_rooms_events, :card_reader_id
  end

end
