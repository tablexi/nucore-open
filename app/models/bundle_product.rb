class BundleProduct < ActiveRecord::Base
  belongs_to :bundle, :foreign_key => :bundle_product_id
  belongs_to :product
  
  validates_presence_of     :bundle_product_id, :product_id
  validates_numericality_of :quantity, :only_integer => true, :greater_than => 0
  validates_uniqueness_of   :product_id, :scope => [:bundle_product_id]
  validate                  :instrument_quantity
  
  def instrument_quantity
    errors.add("quantity", " must be 1 for instruments") if (product && product.is_a?(Instrument) && quantity.to_i != 1)
  end

  def <=>(other)
    self.product.name <=> other.product.name
  end
end