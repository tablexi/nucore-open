module TimelineHelper
  def reservation_classes(reservation, classes=nil)
    classes = ['unit']
    classes << 'tip' unless reservation.blackout?
    classes << 'blackout' if reservation.blackout?
    classes << 'admin' if reservation.admin?
    classes << 'behalf_of' if reservation.ordered_on_behalf_of?
    classes << 'in_progress' if reservation.can_switch_instrument?
    classes << "status_#{reservation.order_detail.order_status.to_s.downcase}" if reservation.order_detail
    classes.join(" ")
  end
end