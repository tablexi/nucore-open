class ProductDisplayGroupProduct < ApplicationRecord

  belongs_to :product_display_group, inverse_of: :product_display_group_products, required: true
  belongs_to :product, required: true

end
