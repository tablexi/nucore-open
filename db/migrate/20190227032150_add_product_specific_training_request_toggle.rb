class AddProductSpecificTrainingRequestToggle < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :allows_training_requests, :boolean, default: true, null: false, after: :requires_approval
  end
end
