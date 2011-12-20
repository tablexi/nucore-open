class AddRecoverableToUser < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.recoverable
    end
  end

  def self.down
    remove_column :users, :reset_password_token
  end
end
