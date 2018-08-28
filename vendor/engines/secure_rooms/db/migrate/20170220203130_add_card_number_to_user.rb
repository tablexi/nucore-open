# frozen_string_literal: true

class AddCardNumberToUser < ActiveRecord::Migration

  def change
    add_column :users, :card_number, :string
    add_index :users, :card_number
  end

end
