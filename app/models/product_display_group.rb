class ProductDisplayGroup < ApplicationRecord

  belongs_to :facility
  has_many :product_display_group_products
  has_many :products, through: :product_display_group_products

  validates :name, presence: true

  def to_s
    name
  end

end
