class AddFacilityOrder < ActiveRecord::Migration
  def self.up
    change_table :orders do |t|
      t.references :facility
      t.foreign_key :facilities
    end
  end

  def self.down
    change_table :orders do |t|
      t.remove_foreign_key :facilities
      t.remove :facility_id
    end
  end
end
