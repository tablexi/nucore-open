# frozen_string_literal: true

class AddOrderState < ActiveRecord::Migration

  def self.up
    change_table :orders do |t|
      t.string :state, limit: 50
    end
  end

  def self.down
    remove_column :orders, :state
  end

end
