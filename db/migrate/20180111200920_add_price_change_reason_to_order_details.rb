class AddPriceChangeReasonToOrderDetails < ActiveRecord::Migration
  def change
    add_column :order_details, :price_change_reason, :string
    add_column :order_details, :price_changed_by_user_id, :integer

    add_index :order_details, :price_changed_by_user_id
  end
end
