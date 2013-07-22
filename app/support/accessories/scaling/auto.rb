# defaults to the duration length of the reservation
# and auto-updates if the duration changes
class Accessories::Scaling::Auto < Accessories::Scaling::Manual
  def update_quantity
    @order_detail.quantity = @order_detail.parent_order_detail.reservation.actual_duration_mins.to_i
  end

  def quantity_editable?
    false
  end
end
