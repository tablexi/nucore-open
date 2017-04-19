class CreateEvents < ActiveRecord::Migration

  def change
    create_table :secure_rooms_events do |t|
      t.references :card_reader
      t.references :user

      t.datetime :occurred_at
      t.string :outcome
      t.string :outcome_details

      t.timestamps null: false
    end

    if NUCore::Database.oracle?
      add_index :secure_rooms_events, :user_id, name: "index_rooms_events_on_user_id"
      add_index :secure_rooms_events, :card_reader_id, name: "index_events_on_card_rdr_id"
    else
      add_index :secure_rooms_events, :user_id
      add_index :secure_rooms_events, :card_reader_id
    end
  end

end
