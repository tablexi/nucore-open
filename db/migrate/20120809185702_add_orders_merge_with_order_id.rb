# frozen_string_literal: true

class AddOrdersMergeWithOrderId < ActiveRecord::Migration

  def self.up
    add_column :orders, :merge_with_order_id, :integer
  end

  def self.down
    remove_column :orders, :merge_with_order_id
  end

end
