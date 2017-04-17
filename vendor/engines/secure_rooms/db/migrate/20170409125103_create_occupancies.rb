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

      t.datetime :orphaned_at

      t.timestamps null: false
    end

    add_foreign_key :secure_rooms_occupancies, :products
    add_foreign_key :secure_rooms_occupancies, :users
    add_foreign_key :secure_rooms_occupancies, :accounts

    add_foreign_key :secure_rooms_occupancies, :secure_rooms_events, column: :entry_event_id
    add_foreign_key :secure_rooms_occupancies, :secure_rooms_events, column: :exit_event_id
  end

end
