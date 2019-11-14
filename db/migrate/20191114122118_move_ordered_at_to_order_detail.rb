class MoveOrderedAtToOrderDetail < ActiveRecord::Migration[5.0]
  def up
    change_table :order_details do |t|
      t.datetime :ordered_at
    end
    execute "UPDATE order_details JOIN orders ON orders.id = order_details.order_id SET order_details.ordered_at = orders.ordered_at"
    change_table :orders do |t|
      t.remove :ordered_at
    end
  end

  def down
    change_table :orders do |t|
      t.datetime :ordered_at, after: :updated_at
    end
    # This will lose data if the ordered_at of a detail is ever changed
    execute "UPDATE orders SET orders.ordered_at = (SELECT MAX(order_details.ordered_at) from order_details where order_details.order_id = orders.id)"
    change_table :order_details do |t|
      t.remove :ordered_at
    end
  end
end
