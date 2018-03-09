class MostRecentlyUsedSearcher
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def recently_used_facilities(limit = 5)
    return [] unless user

    # facility_ids = user.orders.purchased.order("MAX(ordered_at) DESC").limit(limit).group(:facility_id).pluck(:facility_id)
    # Facility.where(id: facility_ids).active.sorted

    Facility.active.joins(products: { order_details: :order }).merge(Order.for_user(user).group("orders.facility_id").order('MAX(orders.ordered_at) DESC')).limit(limit)
  end

  def recently_used_products(limit = 10)
    return [] unless user

    Product.active.in_active_facility.joins(order_details: :order).merge(Order.for_user(user).group(:product_id).order('MAX(orders.ordered_at) DESC')).limit(limit)

    # user.order_details.purchased.joins(:product).merge(Product.active.in_active_facility).group(:product_id).order("MAX(orders.ordered_at) DESC").limit(10).map(&:product)
  end

end
