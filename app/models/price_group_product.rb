class PriceGroupProduct < ActiveRecord::Base
  DEFAULT_RESERVATION_WINDOW=14

  belongs_to :price_group
  belongs_to :product
  validates_presence_of :price_group_id, :product_id
end
