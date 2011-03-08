class ChangeReservations < ActiveRecord::Migration
  def self.up
    change_table :reservations do |t|
      t.references  :order_detail
      t.foreign_key :order_detail
      t.references  :instrument, :null => false
      t.foreign_key :product, :column => :instrument_id
      t.datetime    :reserve_start_at, :null => false
      t.datetime    :reserve_end_at,   :null => false
      t.datetime    :actual_start_at
      t.datetime    :actual_end_at
    end
  end

  def self.down
    change_table :reservations do |t|
      t.remove   :order_detail_id
      t.remove   :instrument_id
      t.remove   :reserve_start_at
      t.remove   :reserve_end_at
      t.remove   :actual_start_at
      t.remove   :actual_end_at
    end
  end
end
