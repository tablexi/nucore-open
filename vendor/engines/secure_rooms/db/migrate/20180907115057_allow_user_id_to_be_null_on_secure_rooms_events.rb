# frozen_string_literal: true

class AllowUserIdToBeNullOnSecureRoomsEvents < ActiveRecord::Migration

  def change
    change_column :secure_rooms_events, :user_id, :integer, null: true
  end

end
