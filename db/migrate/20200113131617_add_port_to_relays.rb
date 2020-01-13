class AddPortToRelays < ActiveRecord::Migration[5.0]
  def change
    add_column :relays, :port, :integer, null: true
  end
end
