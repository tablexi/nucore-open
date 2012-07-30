class Item < Product
  has_many :item_price_policies, :foreign_key => :product_id
end
