# frozen_string_literal: true

class MostRecentlyUsedSearcher

  attr_reader :user

  def initialize(user)
    @user = user
  end

  def recently_used_facilities(limit = 5)
    return Facility.none unless user

    facility_ids = user.orders.purchased.order("MAX(ordered_at) DESC").limit(limit).group(:facility_id).pluck(:facility_id)
    Facility.where(id: facility_ids)
  end

  def recently_used_products(limit = 10)
    return Product.none unless user

    product_ids = user.orders.joins(order_details: :product).merge(Product.active.in_active_facility).purchased.order("MAX(orders.ordered_at) DESC").limit(limit).group(:product_id).pluck(:product_id)
    Product.where(id: product_ids)
  end

end
