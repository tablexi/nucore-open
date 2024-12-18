class AddProductFixedStartTime < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :fixed_start_time, :boolean, default: false, null: false
  end
end
