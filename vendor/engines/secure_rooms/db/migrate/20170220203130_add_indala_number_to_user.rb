class AddIndalaNumberToUser < ActiveRecord::Migration
  def change
    add_column :users, :indala_number, :string
  end
end
