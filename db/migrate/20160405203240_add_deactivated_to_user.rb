# frozen_string_literal: true

class AddDeactivatedToUser < ActiveRecord::Migration

  def change
    add_column :users, :deactivated_at, :timestamp
  end

end
