# Defaults to the duration length of the reservation,
# but does not get auto-updated
class Accessories::Scaling::Manual < Accessories::Scaling::Default
  def default_quantity
    @order_detail.reservation.actual_duration_mins
  end
end
