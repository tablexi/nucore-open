# defaults to the duration length of the reservation
# and auto-updates if the duration changes
class Accessories::Scaling::Auto < Accessories::Scaling::Manual
  def updated_quantity
    @order_detail.reservation.actual_duration_mins
  end
end
