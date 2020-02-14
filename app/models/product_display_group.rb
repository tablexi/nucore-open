class ProductDisplayGroup < ApplicationRecord

  belongs_to :facility
  has_many :product_display_group_products
  has_many :products, through: :product_display_group_products

  validates :name, presence: true

  scope :sorted, -> { order(:display_order) }

  def to_s
    name
  end

  Fake = Struct.new(:name, :products, keyword_init: true) do
    def to_s
      name
    end
  end

  def self.fake_groups_by_type(products)
    Product.types.map do |type|
      Fake.new(name: type.model_name.human(count: :many), products: products.where(type: type.to_s))
    end

  end

end
