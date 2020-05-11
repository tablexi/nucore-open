class SingleReservationsController < ApplicationController

  customer_tab  :all
  before_action :authenticate_user!
  load_resource :facility, find_by: :url_name
  load_resource :instrument, through: :facility, find_by: :url_name
  before_action :build_order
  before_action { @submit_action = facility_instrument_single_reservations_path }

  def new
    options = current_user.can_override_restrictions?(@instrument) ? {} : { user: acting_user }
    next_available = @instrument.next_available_reservation(after: 1.minute.from_now, duration: default_reservation_mins.minutes, options: options)
    @reservation = next_available || default_reservation
    @reservation.order_detail = @order_detail

    authorize! :new, @reservation

    @reservation.round_reservation_times
    unless @instrument.can_be_used_by?(acting_user)
      flash[:notice] = text(".acting_as_not_on_approval_list")
    end
    set_windows
    render "reservations/new"
  end

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

  def default_reservation
    Reservation.new(instrument: @instrument,
                    reserve_start_at: Time.zone.now,
                    reserve_end_at: default_reservation_mins.minutes.from_now)
  end

  def default_reservation_mins
    @instrument.min_reserve_mins.to_i > 0 ? @instrument.min_reserve_mins : 30
  end

  def set_windows
    @max_window = max_reservation_window
    @max_days_ago = session_user.operator_of?(@facility) ? -365 : 0
    # initialize calendar time constraints
    @min_date     = (Time.zone.now + @max_days_ago.days).strftime("%Y%m%d")
    @max_date     = (Time.zone.now + @max_window.days).strftime("%Y%m%d")
  end

  def max_reservation_window
    return 365 if session_user.operator_of?(current_facility)
    @reservation.longest_reservation_window(current_user.price_groups)
  end

end
