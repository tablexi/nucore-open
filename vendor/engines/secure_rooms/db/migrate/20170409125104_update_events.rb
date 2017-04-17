class UpdateEvents < ActiveRecord::Migration

  def change
    change_column :secure_rooms_events, :card_reader_id, :integer, null: false
    change_column :secure_rooms_events, :user_id, :integer, null: false
    add_column :secure_rooms_events, :account_id, :integer
  end

end
