# frozen_string_literal: true

class BundleProduct < ApplicationRecord

  belongs_to :bundle, foreign_key: :bundle_product_id
  belongs_to :product

  validates_presence_of     :bundle_product_id, :product_id
  validates_numericality_of :quantity, only_integer: true, greater_than: 0
  validates_uniqueness_of   :product_id, scope: [:bundle_product_id]
  validate                  :instrument_quantity

  scope :alphabetized, -> { joins(:product).order("lower(products.name)") }

  def instrument_quantity
    errors.add("quantity", " must be 1 for instruments") if product && product.is_a?(Instrument) && quantity.to_i != 1
  end

  # TODO: favor the alphabetized scope over relying on Array#sort
  def <=>(other)
    product.name <=> other.product.name
  end

end
