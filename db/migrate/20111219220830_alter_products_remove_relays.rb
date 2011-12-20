class AlterProductsRemoveRelays < ActiveRecord::Migration
  def self.up
    remove_columns(
        :products,
        :relay_ip,
        :relay_port,
        :relay_username,
        :relay_password,
        :relay_type,
        :auto_logout
    )
  end

  def self.down
    change_table :products do |t|
      t.column "relay_ip", :string, :limit => 15
      t.column "relay_port", :integer
      t.column "relay_username", :string, :limit => 50
      t.column "relay_password", :string, :limit => 50
      t.column "auto_logout", :boolean
      t.column "relay_type", :string, :limit => 50
    end
  end
end
