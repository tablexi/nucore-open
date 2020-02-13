class ProductDisplayGroupProduct < ApplicationRecord

  belongs_to :product_display_group, required: true
  belongs_to :product, required: true

end
