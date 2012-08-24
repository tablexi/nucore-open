class CreateNotifications < ActiveRecord::Migration
  def self.up
    create_table :notifications do |t|
      t.column :user_id, :integer, :null => false
      t.column :created_by, :integer, :null =>false
      t.column :created_by_type, :string, :null => false
      t.column :notice, :string, :null => false
      t.column :dismissed_at, :timestamp
      t.timestamps
    end
  end

  def self.down
    drop_table :notifications
  end
end
