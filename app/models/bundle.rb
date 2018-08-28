# frozen_string_literal: true

class Bundle < Product

  has_many :products, through: :bundle_products
  has_many :bundle_products, foreign_key: :bundle_product_id

  cattr_accessor(:bundleable_product_types) { ["Instrument", "Item", "Service", "TimedService"] }

  def products_for_group_select
    products = facility.products.where(type: bundleable_product_types).order(:type, :name)
    options = Hash.new { |h, k| h[k] = [] }
    products.group_by { |product| product.class.model_name.human.pluralize }.each do |cname, ps|
      options[cname] = ps.map { |p| [p.to_s_with_status, p.id] }
    end
    options
  end

  def products_active?
    return true if products.empty? && !is_archived?
    return false if products.empty? || products.any?(&:is_archived?)
    true
  end

  def can_purchase?(group_ids = nil)
    return false unless available_for_purchase?
    # before if products.empty?, this would return and empty set [], which evaluates to true
    return false if products.empty?
    products.each do |p|
      return false unless p.can_purchase?(group_ids)
    end
  end

  def products_missing_price_policies
    products.select { |p| p.current_price_policies.none? }
  end

  private

  def requires_account?
    false
  end

end
