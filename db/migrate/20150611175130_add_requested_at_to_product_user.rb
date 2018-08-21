# frozen_string_literal: true

class AddRequestedAtToProductUser < ActiveRecord::Migration

  def change
    add_column :product_users, :requested_at, :datetime, null: true
  end

end
