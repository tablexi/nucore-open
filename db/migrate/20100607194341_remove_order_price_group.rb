# frozen_string_literal: true

class RemoveOrderPriceGroup < ActiveRecord::Migration

  def self.up
    remove_column :orders, :price_group_id
  end

  def self.down
    add_column :orders, :price_group_id, :integer, null: true
  end

end
