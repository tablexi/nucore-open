class AddMoreIndexes < ActiveRecord::Migration
  def change
    add_index :order_details, :state
  end
end
