class ProductDisplayGroup < ApplicationRecord

  belongs_to :facility
  has_many :product_display_group_products, inverse_of: :product_display_group, dependent: :destroy
  has_many :products,  -> { alphabetized }, through: :product_display_group_products

  validates :name, presence: true

  before_save :set_default_display_order, on: :create

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
    Product.orderable_types.map do |type|
      Fake.new(name: type.constantize.model_name.human(count: :many), products: products.where(type: type))
    end
  end

  def set_default_display_order
    self.display_order = facility.product_display_groups.maximum(:display_order).to_i + 1
  end

end
