module ReservationsHelper
  def add_accessories_link(reservation)
    accessories = reservation.product.product_accessories.for_acting_as(acting_as?)
    if accessories.present? && reservation.reserve_end_at < Time.zone.now
      link_to t('product_accessories.pick_accessories.link'), reservation_pick_accessories_path(reservation), :class => 'has_accessories persistent'
    end
  end

  def reservation_pick_accessories_path(reservation)
    order_order_detail_reservation_pick_accessories_path(reservation.order_detail.order, reservation.order_detail, reservation)
 end
end