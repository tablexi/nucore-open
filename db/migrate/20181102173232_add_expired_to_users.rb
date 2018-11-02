class AddExpiredToUsers < ActiveRecord::Migration[5.0]

  def change
    add_column :users, :expired_at, :datetime
    add_column :users, :expired_note, :string
  end

end
