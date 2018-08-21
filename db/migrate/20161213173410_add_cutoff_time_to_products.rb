# frozen_string_literal: true

class AddCutoffTimeToProducts < ActiveRecord::Migration

  def change
    add_column :products, :cutoff_hours, :integer, null: false, default: 0
  end

end
