# frozen_string_literal: true

class AddSangerOptionToFacility < ActiveRecord::Migration

  def change
    add_column :facilities, :sanger_sequencing_enabled, :boolean, null: false, default: false
  end

end
