class Cart
  def initialize(user, created_by_user = nil)
    @user = user
    @created_by_user = created_by_user || @user
  end

  def order
    non_reservation_only_cart || new_cart
  end

  def new_cart
    Order.create(:user => @user,
      :created_by => @created_by_user.id)
  end

private

  # Will find the first cart that either has a non-instrument,
  # has multiple items, or is empty
  def non_reservation_only_cart
    all_carts.find { |order| order.order_details.non_reservations.any? || order.order_details.size != 1 }
  end

  def all_carts
    @user.orders.
      created_by_user(@created_by_user).
      carts.order('updated_at DESC')
  end
end
