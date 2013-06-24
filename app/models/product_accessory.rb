class ProductAccessory < ActiveRecord::Base
  SCALING_TYPES = ['quantity', 'manual', 'auto']

  ## relationships
  belongs_to :product
  belongs_to :accessory, :class_name => 'Product', :foreign_key => :accessory_id

  ## validations
  validates :product, :presence => true
  validates :accessory, :presence => true
  validates :scaling_type, :presence => true, :inclusion => SCALING_TYPES

  ## scopes
  def self.for_acting_as(is_acting_as)
    if is_acting_as
      scoped
    else
      joins(:accessory).where('products.is_hidden = ?', false)
    end
  end

  def self.scaling_types
    SCALING_TYPES
  end
end
