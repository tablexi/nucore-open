# frozen_string_literal: true

class AddProjectIdToOrderDetail < ActiveRecord::Migration

  def change
    add_column :order_details, :project_id, :integer, null: true
  end

end
