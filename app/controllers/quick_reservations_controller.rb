# frozen_string_literal: true

class QuickReservationsController < ApplicationController
  layout "quick_reservation"

  before_action :authenticate_user!
  load_resource :facility, find_by: :url_name
  load_resource :instrument, through: :facility, find_by: :url_name
  before_action :get_startable_reservation, only: [:index, :start]
  before_action :prepare_reservation_data, only: [:new, :create]

  # GET /facilities/:facility_id/instruments/:instrument_id/quick_reservations
  def index
    redirect_to(new_facility_instrument_quick_reservation_path) unless @startable || @ongoing
  end

  # GET /facilities/:facility_id/instruments/:instrument_id/quick_reservations/new
  def new
    interval = @instrument.quick_reservation_intervals.first
    @walkup_available = @instrument.walkup_available?(interval:)
  end

  # POST /facilities/:facility_id/instruments/:instrument_id/quick_reservations
  def create
    # This will give reservation data that's valid the instant of creation. If
    # a user sits on the #new page for a little bit of time, the data shown
    # on that page will not longer create a valid, startable reservation.
    params[:reservation][:reserve_start_date] = @reservation_data[:reserve_start_at].to_s
    params[:reservation][:reserve_start_hour] = @reservation_data[:reserve_start_at].hour
    params[:reservation][:reserve_start_min] = @reservation_data[:reserve_start_at].min
    params[:reservation][:reserve_start_meridian] = @reservation_data[:reserve_start_at].strftime("%p")

    build_order
    creator = ReservationCreator.new(@order, @order_detail, params)

    if creator.save(current_user)
      @order.transaction do
        order_purchaser.purchase!
      end

      if order_purchaser.success?
        if creator.reservation.send(:in_grace_period?)
          creator.reservation.start_reservation!
        end
      else
        # failed to purchase order
      end
    else
      # failed to save reservation
    end

    redirect_to facility_instrument_quick_reservations_path(@facility, @instrument)
  end

  # POST /facilities/:facility_id/instruments/:instrument_id/quick_reservations/start
  def start
    if @startable.move_to_earliest && @startable.start_reservation!
      flash[:notice] = "Reservation started"
      redirect_to facility_instrument_quick_reservations_path(@facility, @instrument)
    end
  end

  private

  def reservation_params
    params.permit(:reservation, :order_account)
  end

  def prepare_reservation_data
    @possible_reservation_data = @instrument.quick_reservation_data

    # if no reservations are available right now, find reservations at the next
    # available time
    if @possible_reservation_data.empty?
      duration = @instrument.quick_reservation_intervals.first.minutes
      next_available_reservation = @instrument.next_available_reservation(duration:)
      after = next_available_reservation.reserve_start_at
      @possible_reservation_data = @instrument.quick_reservation_data(after:)
    end

    @reservation_data = @possible_reservation_data.first
  end

  def get_startable_reservation
    @reservations = current_user.reservations.where(product_id: @instrument.id)
    @startable = @reservations.find(&:startable_now?)
    @ongoing = @reservations.ongoing.first
  end

  def build_order
    @order = Order.new(
      user: current_user,
      facility: current_facility,
      created_by: current_user.id,
    )
    @order_detail = @order.order_details.build(
      product: @instrument,
      quantity: 1,
      created_by: current_user.id,
    )
  end

  def order_purchaser
    @order_purchaser ||= OrderPurchaser.new(
      acting_as: false,
      order: @order,
      order_in_past: false,
      params: params,
      user: current_user,
    )
  end
end
