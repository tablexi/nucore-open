# frozen_string_literal: true

class AllowUserIdToBeNullOnSecureRoomsEvents < ActiveRecord::Migration

  def up
    change_column :secure_rooms_events, :user_id, :integer, null: true
  end

  def down
    change_column :secure_rooms_events, :user_id, :integer, null: false
  end

end
