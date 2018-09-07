class AddCardNumberToSecureRoomsEvents < ActiveRecord::Migration
  def up
    add_column :secure_rooms_events, :card_number, :string
    update <<~END_OF_SQL
      UPDATE secure_rooms_events
      SET card_number =
        (SELECT card_number
         FROM users
         WHERE users.id = secure_rooms_events.user_id)
    END_OF_SQL
    change_column :secure_rooms_events, :card_number, :string, null: false
  end

  def down
    remove_column :secure_rooms_events, :card_number
  end
end
