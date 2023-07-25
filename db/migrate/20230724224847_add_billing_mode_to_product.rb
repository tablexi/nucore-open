class AddBillingModeToProduct < ActiveRecord::Migration[6.1]
  def change
    add_column :products, :billing_mode, :string
  end
end
