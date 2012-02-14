class ProductAccessory < ActiveRecord::Base
  belongs_to :product
  belongs_to :accessory, :class_name => 'Product', :foreign_key => :accessory_id
end
