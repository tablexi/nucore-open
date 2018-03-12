class MostRecentlyUsedSearcher

  attr_reader :user

  def initialize(user)
    @user = user
  end

  def recently_used_facilities(limit = 5)
    return [] unless user

    Facility.active
      .joins(products: { order_details: :order })
      .merge(Order.for_user(user)
        .group(:id)
        .order('MAX(orders.ordered_at) DESC'))
      .limit(limit)
  end

  def recently_used_products(limit = 10)
    return [] unless user

    Product.active.in_active_facility
      .joins(order_details: :order)
      .merge(Order.for_user(user)
        .group(:id)
        .order('MAX(orders.ordered_at) DESC'))
      .limit(limit)
  end

end
