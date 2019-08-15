class AddEmailPurchasersOnOrderStatusChangesToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :email_purchasers_on_order_status_changes, :boolean, default: false, null: false
  end
end
