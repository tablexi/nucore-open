class AddOriginalCrossCoreOrderToOrders < ActiveRecord::Migration[7.0]
  def up
    add_column :orders, :original_cross_core_order, :boolean, default: false, null: false

    Projects::Project.find_each do |project|
      next unless project.orders.any?

      original_order = project.orders.where(facility_id: project.facility_id).first

      original_order&.update!(original_cross_core_order: true)
    end
  end

  def down
    remove_column :orders, :original_cross_core_order
  end
end
