# frozen_string_literal: true

class AddLockWindowToProducts < ActiveRecord::Migration

  def change
    add_column :products, :lock_window, :integer, null: false, default: 0
  end

end
