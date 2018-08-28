# frozen_string_literal: true

class AddActiveFacilitiesIndex < ActiveRecord::Migration

  def change
    add_index :facilities, [:is_active, :name]
  end

end
