class AddCardNumberToUser < ActiveRecord::Migration

  def change
    add_column :users, :card_number, :string
  end

end
