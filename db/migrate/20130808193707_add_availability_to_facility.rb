# frozen_string_literal: true

class AddAvailabilityToFacility < ActiveRecord::Migration

  def change
    add_column :facilities, :show_instrument_availability, :boolean, default: false, null: false
  end

end
