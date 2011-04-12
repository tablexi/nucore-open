class PriceGroupProduct < ActiveRecord::Base
  belongs_to :price_group
  belongs_to :product
  validates_presence_of :price_group_id, :product_id
end
