# frozen_string_literal: true

class MakeJournalsFacilityIdNullable < ActiveRecord::Migration

  def self.up
    change_column :journals, :facility_id, :integer, null: true
  end

  def self.down
    change_column :journals, :facility_id, :integer, null: false
  end

end
