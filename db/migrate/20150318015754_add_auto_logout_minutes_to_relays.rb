class AddAutoLogoutMinutesToRelays < ActiveRecord::Migration
  def change
    add_column :relays, :auto_logout_minutes, :integer, null: false, default: 60
  end
end
