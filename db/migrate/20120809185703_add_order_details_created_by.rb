class AddOrderDetailsCreatedBy < ActiveRecord::Migration
  def self.up
    add_column :order_details, :created_by, :integer, :null => false

    OrderDetail.reset_column_information

    Order.all.each do |order|
      order.order_details.each{|detail| detail.update_attribute :created_by, order.created_by }
    end
  end

  def self.down
    remove_column :order_details, :created_by
  end
end
