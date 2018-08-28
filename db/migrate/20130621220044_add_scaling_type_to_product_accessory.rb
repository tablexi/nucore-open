# frozen_string_literal: true

class AddScalingTypeToProductAccessory < ActiveRecord::Migration

  def change
    add_column :product_accessories, :scaling_type, :string, null: false, default: :quantity
  end

end
