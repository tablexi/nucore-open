class CreateOccupancies < ActiveRecord::Migration

  def change
    create_table :secure_rooms_occupancies do |t|
      t.references :product, null: false
      t.references :user, null: false
      t.references :account

      t.references :entry_event
      t.datetime :entry_at
      t.references :exit_event
      t.datetime :exit_at

      t.datetime :orphan

      t.timestamps null: false
    end

    add_index :secure_rooms_occupancies, :product_id
    add_index :secure_rooms_occupancies, :user_id
    add_index :secure_rooms_occupancies, :account_id
    add_index :secure_rooms_occupancies, :entry_event_id
    add_index :secure_rooms_occupancies, :exit_event_id
  end

end
