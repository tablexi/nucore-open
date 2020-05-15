class SingleReservationsController < ApplicationController

  customer_tab  :all
  before_action :authenticate_user!
  load_resource :facility, find_by: :url_name
  load_resource :instrument, through: :facility, find_by: :url_name
  before_action :build_order
  before_action { @submit_action = facility_instrument_single_reservations_path }

  # GET /facilities/:facility_slug/instruments/:instument/slug/single_reservations/new
  #
  # This code is very, very similar to ReservationsController#new. However, the
  # before_actions are different. We decided that was ok since this is mostly controller-level code left
  # and it feels like it would be more confusing to try to share the code.
  def new
    @reservation = NextAvailableReservationFinder.new(@instrument).next_available_for(current_user, acting_user)
    @reservation.order_detail = @order_detail

    authorize! :new, @reservation

    unless @instrument.can_be_used_by?(acting_user)
      flash[:notice] = text(".acting_as_not_on_approval_list")
    end
    set_windows
    render "reservations/new"
  end

  # GET /facilities/:facility_slug/instruments/:instument/slug/single_reservations
  def create
    creator = ReservationCreator.new(@order, @order_detail, params)
    if creator.save(session_user)
      @reservation = creator.reservation
      authorize! :create, @reservation
      flash[:notice] = I18n.t "controllers.reservations.create.success"
      flash[:error] = I18n.t("controllers.reservations.create.admin_hold_warning") if creator.reservation.conflicting_admin_reservation?

      redirect_to purchase_order_path(@order, params.permit(:send_notification))
    else
      @reservation = creator.reservation
      flash.now[:error] = creator.error.html_safe
      set_windows
      render "reservations/new"
    end
  end

  private

  def ability_resource
    @reservation
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

  def set_windows
    @reservation_window = ReservationWindow.new(@reservation, current_user)
  end

end
