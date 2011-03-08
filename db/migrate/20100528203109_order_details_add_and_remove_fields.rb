class OrderDetailsAddAndRemoveFields < ActiveRecord::Migration
  def self.up
    remove_column :order_details, :order_status_id
    remove_column :order_details, :unit_cost
    remove_column :order_details, :unit_subsidy
    remove_column :order_details, :reservation_id
    
    add_column :order_details, :estimated_cost,    :decimal, :precision => 10, :scale => 2, :null => true
    add_column :order_details, :estimated_subsidy, :decimal, :precision => 10, :scale => 2, :null => true
  end

  def self.down
    add_column :order_details, :order_status_id, :integer,                               :null => true
    add_column :order_details, :unit_cost,       :decimal, :precision => 8, :scale => 2, :null => true
    add_column :order_details, :unit_subsidy,    :decimal, :precision => 8, :scale => 2, :null => true
    add_column :order_details, :reservation_id,  :integer,                               :null => true
    
    remove_column :order_details, :estimated_cost
    remove_column :order_details, :estimated_subsidy
  end
end
