class ReservationUserActionPresenter
  attr_accessor :reservation, :controller
  delegate :order_detail, :order,
           :can_switch_instrument?, :can_switch_instrument_on?, :can_switch_instrument_off?,
           :can_cancel?, :can_move?, :can_customer_edit?, to: :reservation
  delegate :current_facility, to: :controller

  delegate :link_to, to: 'ActionController::Base.helpers'
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::NumberHelper
  include ReservationsHelper

  def initialize(controller, reservation)
    @reservation = reservation
    @controller = controller
  end

  def user_actions
    actions = []
    actions << switch_actions if can_switch_instrument?
    actions << cancel_link if can_cancel?
    actions << move_link if can_move?
    actions.compact.join('&nbsp;|&nbsp;').html_safe
  end

  def view_edit_link
    if can_customer_edit?
      link_to reservation, edit_reservation_path
    else
      link_to reservation, view_reservation_path
    end
  end

  private

  def edit_reservation_path
    current_facility ? edit_facility_order_order_detail_reservation_path(current_facility, order, order_detail, reservation) : edit_order_order_detail_reservation_path(order, order_detail, reservation)
  end

  def view_reservation_path
    current_facility ? facility_order_order_detail_reservation_path(current_facility, order, order_detail, reservation) : order_order_detail_reservation_path(order, order_detail, reservation)
  end

  def switch_actions
    if can_switch_instrument_on?
      link_to I18n.t('reservations.switch.start'),
              order_order_detail_reservation_switch_instrument_path(order, order_detail, reservation, :switch => 'on')
    elsif can_switch_instrument_off?
      link_to I18n.t('reservations.switch.end'),
              order_order_detail_reservation_switch_instrument_path(order, order_detail, reservation, :switch => 'off'),
              :class => end_reservation_class(reservation),
              :data => { :refresh_on_cancel => true }
    end
  end

  def cancel_link
    fee = order_detail.cancellation_fee
    if fee > 0
      link_to("Cancel", order_order_detail_path(order, order_detail, :cancel => 'cancel'),
        :method => :put,
        :confirm => "Canceling this reservation will incur a #{number_to_currency fee} fee.  Are you sure you wish to cancel this reservation?")
    else
      link_to("Cancel", order_order_detail_path(order, order_detail, :cancel => 'cancel'),
        :method => :put)
    end
  end

  def move_link
    link_to('Begin Now', order_order_detail_reservation_move_reservation_path(order, order_detail, reservation),
      :class => 'move-res',
      :data => { :reservation_id => reservation.id })
  end
end
