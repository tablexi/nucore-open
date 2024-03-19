class AddCrossCoreProjectToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :orders, :cross_core_project_id, :integer, null: true
  end
end
