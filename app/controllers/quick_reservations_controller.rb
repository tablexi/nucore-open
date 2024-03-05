# frozen_string_literal: true

class QuickReservationsController < ApplicationController
  before_action :authenticate_user!
  load_resource :facility, find_by: :url_name
  load_resource :instrument, through: :facility, find_by: :url_name
  before_action :get_startable_reservation, only: [:index, :start]
  before_action :prepare_reservation_data, only: [:new, :create]

  # GET /facilities/:facility_id/instruments/:instrument_id/quick_reservations
  def index
    redirect_to(new_facility_instrument_quick_reservation_path) unless @startable || @ongoing
  end

  def new
    interval = @instrument.quick_reservation_intervals.first
    @walkup_available = @instrument.walkup_available?(interval:)
  end

  def create
    index = reservation_params[:reservation_index].to_i
    account = Account.find(reservation_params[:account])
    reservation = @possible_reservations[index]

    build_order

    # Borrowed from ReservationCreator
    @order.account = account
    validator = OrderPurchaseValidator.new(@order_detail)
    raise OrderPurchaseValidatorError, @order_detail if validator.invalid?
    reservation.order_detail = @order_detail
    reservation.save_as_user!(current_user)
    @order_detail.assign_estimated_price(reservation.reserve_end_at)
    @order_detail.save_as_user!(current_user)

    if reservation.send(:in_grace_period?)
      reservation.start_reservation!
    end

    redirect_to facility_instrument_quick_reservations_path(@facility, @instrument)
  end

  def start
    if @startable.move_to_earliest && @startable.start_reservation!
      flash[:notice] = "Reservation started"
      redirect_to facility_instrument_quick_reservations_path(@facility, @instrument)
    end
  end

  private

  def reservation_params
    params.permit(:reservation_index, :account)
  end

  def prepare_reservation_data
    @reservation_intervals = @instrument.quick_reservation_intervals
    @possible_reservations = @instrument.quick_reservation_reservations

    # if no reservations are available right now, find reservations at the next
    # available time
    if @possible_reservations.empty?
      duration = @reservation_intervals.first.minutes
      next_available_reservation = @instrument.next_available_reservation(duration:)
      after = next_available_reservation.reserve_start_at
      @possible_reservations = @instrument.quick_reservation_reservations(after:)
    end

    @reservation_intervals.pop((@possible_reservations.count - 3).abs)
    @reservation = @possible_reservations.first
  end

  def get_startable_reservation
    @reservations = current_user.reservations.where(product_id: @instrument.id)
    @startable = @reservations.find(&:startable_now?)
    @ongoing = @reservations.ongoing.first
  end

  def build_order
    @order = Order.new(
      user: acting_user,
      facility: current_facility,
      created_by: session_user.id,
    )
    @order_detail = @order.order_details.build(
      product: @instrument,
      quantity: 1,
      created_by: session_user.id,
    )
  end
end
