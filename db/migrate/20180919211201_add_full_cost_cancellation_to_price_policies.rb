# frozen_string_literal: true

class AddFullCostCancellationToPricePolicies < ActiveRecord::Migration[5.0]

  def change
    add_column :price_policies, :full_cancellation_cost, :boolean, default: false, null: false
  end

end
