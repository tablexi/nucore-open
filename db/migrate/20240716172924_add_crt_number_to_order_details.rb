class AddCrtNumberToOrderDetails < ActiveRecord::Migration[7.0]
  def change
    change_table :order_details do |t|
      t.string :crt_number, limit: 256
    end
  end
end
