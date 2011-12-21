class AddRecoverableToUser < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.recoverable
      t.datetime :reset_password_sent_at
    end
  end

  def self.down
    remove_column :users, :reset_password_token
    remove_column :users, :reset_password_sent_at
  end
end
