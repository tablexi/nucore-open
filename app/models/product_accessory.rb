class ProductAccessory < ActiveRecord::Base
  ## relationships
  belongs_to :product
  belongs_to :accessory, :class_name => 'Product', :foreign_key => :accessory_id
  
  ## validations
  validates :product, :presence => true
  validates :accessory, :presence => true

end
