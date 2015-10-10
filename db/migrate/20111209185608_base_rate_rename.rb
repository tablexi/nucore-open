class BaseRateRename < ActiveRecord::Migration
  def self.up
    pg = PriceGroup.find_by_name 'Northwestern Base Rate'
    pg.update_attribute(:name, 'Base Rate') if pg
  end

  def self.down
    pg = PriceGroup.find_by_name 'Base Rate'
    pg.update_attribute(:name, 'Northwestern Base Rate') if pg
  end
end
