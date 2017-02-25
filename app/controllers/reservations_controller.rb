class ReservationsController < ApplicationController

  include Timelineable

  customer_tab  :all
  before_action :authenticate_user!, except: [:index]
  before_action :check_acting_as, only: [:switch_instrument, :show, :list]
  before_action :load_basic_resources, only: [:new, :create, :edit, :update]
  before_action :load_and_check_resources, only: [:move, :switch_instrument]

  include TranslationHelper
  include FacilityReservationsHelper

  def initialize
    super
    @active_tab = "reservations"
  end

  def public_timeline
    @public_timeline = true
    timeline
  end

  # GET /facilities/1/instruments/1/reservations.js?_=1279579838269&start=1279429200&end=1280034000
  def index
    @facility     = Facility.find_by_url_name!(params[:facility_id])
    @instrument   = @facility.instruments.find_by_url_name!(params[:instrument_id])

    @start_at     = params[:start] ? Time.zone.at(params[:start].to_i) : Time.zone.now
    @start_date   = @start_at.beginning_of_day

    @end_at       = params[:end] ? Time.zone.at(params[:end].to_i) : @start_at.end_of_day

    @admin_reservations = @instrument.schedule.admin_reservations.in_range(@start_at, @end_at)

    @user_reservations = @instrument.schedule
                                    .reservations
                                    .active
                                    .in_range(@start_at, @end_at)
                                    .includes(order_detail: { order: :user })

    @reservations = @admin_reservations + @user_reservations

    @rules        = @instrument.schedule_rules

    # restrict to available if it requires approval and the user
    # isn't a facility admin
    if @instrument.requires_approval && acting_user && acting_user.cannot_override_restrictions?(@instrument)
      @rules = @rules.available_to_user(acting_user)
    end

    # We're not using unavailable rules for month view
    @unavailable = if month_view?
                     []
                   else
                     # build unavailable schedule
                     ScheduleRule.unavailable(@rules)
                   end

    respond_to do |format|
      as_calendar_object_options = { start_date: @start_date, with_details: params[:with_details] }
      format.js do
        render json: @reservations.map { |r| r.as_calendar_object(as_calendar_object_options) }.flatten +
                     @unavailable.map { |r| r.as_calendar_object(as_calendar_object_options) }.flatten
      end
    end
  end

  # GET /reservations
  # All My Resesrvations
  def list
    notices = []

    relation = acting_user.order_details
    in_progress = relation.in_progress_reservations
    @status = params[:status]
    @available_statuses = [in_progress.blank? ? "upcoming" : "upcoming_and_in_progress", "all"]

    if @status == "all"
      @order_details = relation.all_reservations
    elsif @status == "upcoming"
      @status = @available_statuses.first
      @order_details = in_progress + relation.upcoming_reservations
    else
      return redirect_to reservations_status_path(status: "upcoming")
    end

    @order_details = @order_details.paginate(page: params[:page])

    notices = @order_details.collect do |od|
      notice_for_reservation od.reservation
    end
    notices.compact!
    existing_notices = flash[:notice].presence ? [flash[:notice]] : []
    flash.now[:notice] = existing_notices.concat(notices).join("<br />").html_safe unless notices.empty?
  end

  # POST /orders/:order_id/order_details/:order_detail_id/reservations
  def create
    raise ActiveRecord::RecordNotFound unless @reservation.nil?

    creator = ReservationCreator.new(@order, @order_detail, params)
    if creator.save(session_user)
      @reservation = creator.reservation
      flash[:notice] = I18n.t "controllers.reservations.create.success"

      if creator.merged_order?
        redirect_to facility_order_path(@order_detail.facility, @order_detail.order.merge_order || @order_detail.order)
      elsif creator.instrument_only_order?
        redirect_params = {}
        redirect_params[:send_notification] = "1" if params[:send_notification] == "1"
        # only trigger purchase if instrument
        # and is only thing in cart (isn't bundled or on a multi-add order)
        redirect_to purchase_order_path(@order, redirect_params)
      else
        redirect_to cart_path
      end
    else
      @reservation = creator.reservation
      flash.now[:error] = creator.error
      set_windows
      render :new
    end
  end

  # GET /orders/:order_id/order_details/:order_detail_id/reservations/new
  def new
    raise ActiveRecord::RecordNotFound unless @reservation.nil?

    options = current_user.can_override_restrictions?(@instrument) ? {} : { user: acting_user }
    next_available = @instrument.next_available_reservation(after: 1.minute.from_now, duration: default_reservation_mins.minutes, options: options)
    @reservation = next_available || default_reservation
    @reservation.round_reservation_times
    unless @instrument.can_be_used_by?(@order_detail.user)
      flash[:notice] = text(".acting_as_not_on_approval_list")
    end
    set_windows
  end

  # GET /orders/:order_id/order_details/:order_detail_id/reservations/:id(.:format)
  def show
    @order        = Order.find(params[:order_id])
    @order_detail = @order.order_details.find(params[:order_detail_id])
    @reservation  = Reservation.find(params[:id])

    raise ActiveRecord::RecordNotFound if @reservation != @order_detail.reservation
  end

  # GET /orders/1/order_details/1/reservations/1/edit
  def edit
    redirect_to [@order, @order_detail, @reservation] if invalid_for_update?
    set_windows
  end

  # PUT  /orders/1/order_details/1/reservations/1
  def update
    if invalid_for_update?
      redirect_to [@order, @order_detail, @reservation], notice: I18n.t("controllers.reservations.update.failure")
      return
    end

    @reservation.assign_times_from_params(reservation_params)

    render_edit && return unless duration_change_valid?

    Reservation.transaction do
      begin

        # merge state can change after call to #save! due to OrderDetailObserver#before_save
        mergeable = @order_detail.order.to_be_merged?

        save_reservation_and_order_detail

        flash[:notice] = "The reservation was successfully updated."
        if mergeable
          redirect_to facility_order_path(@order_detail.facility, @order_detail.order.merge_order || @order_detail.order)
        else
          redirect_to (@order.purchased? ? reservations_path : cart_path)
        end
        return
      rescue ActiveRecord::RecordInvalid => e
        raise ActiveRecord::Rollback
      end
    end
    render_edit
  end

  # POST /orders/:order_id/order_details/:order_detail_id/reservations/:reservation_id/move
  def move
    if @reservation.move_to_earliest
      flash[:notice] = "The reservation was moved successfully."
    else
      flash[:error] = @reservation.errors.full_messages.join("<br/>")
    end

    redirect_to reservations_status_path(status: "upcoming")
  end

  # GET /orders/:order_id/order_details/:order_detail_id/reservations/:reservation_id/move
  def earliest_move_possible
    @reservation       = Reservation.find(params[:reservation_id])
    @earliest_possible = @reservation.earliest_possible

    if @earliest_possible
      @formatted_dates = {
        start_date: human_date(@earliest_possible.reserve_start_at),
        start_time: human_time(@earliest_possible.reserve_start_at),
        end_date: human_date(@earliest_possible.reserve_end_at),
        end_time: human_time(@earliest_possible.reserve_end_at),
      }
    end

    render layout: false
  end

  # GET /orders/:order_id/order_details/:order_detail_id/reservations/switch_instrument
  def switch_instrument
    authorize! :start_stop, @reservation

    raise ActiveRecord::RecordNotFound unless params[:switch] && (params[:switch] == "on" || params[:switch] == "off")

    begin
      case
      when params[:switch] == "on"
        switch_instrument_on!
      when params[:switch] == "off"
        switch_instrument_off!
      end
    rescue => e
      flash[:error] = e.message
    end

    if params[:switch] == "off" && @order_detail.accessories?
      redirect_to new_order_order_detail_accessory_path(@order, @order_detail)
      return
    end

    redirect_to params[:redirect_to] || request.referer || order_order_detail_path(@order, @order_detail)
  end

  private

  def reservation_params
    reservation_params = params[:reservation].except(
      :actual_start_date,
      :actual_start_hour,
      :actual_start_min,
      :actual_start_meridian,
    )

    reservation_params.merge!(reservation_start_as_params) if fixed_start_time?

    reservation_params
  end

  def fixed_start_time?
    !@reservation.admin_editable? || !@reservation.reserve_start_at_editable?
  end

  def reservation_start_as_params
    {
      reserve_start_date: @reservation.reserve_start_date,
      reserve_start_hour: @reservation.reserve_start_hour,
      reserve_start_min: @reservation.reserve_start_min,
      reserve_start_meridian: @reservation.reserve_start_meridian,
    }
  end

  def switch_instrument_off!
    unless @reservation.other_reservation_using_relay?
      ReservationInstrumentSwitcher.new(@reservation).switch_off!
      flash[:notice] = "The instrument has been deactivated successfully"
    end
    session[:reservation_ended] = true if params[:reservation_ended].present?
  end

  def switch_instrument_on!
    ReservationInstrumentSwitcher.new(@reservation).switch_on!
    flash[:notice] = "The instrument has been activated successfully"
  end

  def load_basic_resources
    @order = Order.find(params[:order_id])
    # It's important that the order_detail be the same object as the one in @order.order_details.first
    @order_detail = @order.order_details.find { |od| od.id.to_i == params[:order_detail_id].to_i }
    raise ActiveRecord::RecordNotFound if @order_detail.blank?
    @reservation = @order_detail.reservation
    @instrument = @order_detail.product
    @facility = @instrument.facility
  rescue ActiveRecord::RecordNotFound
    flash[:error] = text("order_detail_removed")
    redirect_to facility_path(@order.facility)
  end

  def load_and_check_resources
    load_basic_resources
    # @reservation  = @instrument.reservations.find_by_id_and_order_detail_id(params[:reservation_id], @order_detail.id)
    raise ActiveRecord::RecordNotFound if @reservation.blank?
  end

  def ability_resource
    @reservation
  end

  # TODO: you shouldn't be able to edit reservations that have passed or are outside of the cancellation period (check to make sure order has been placed)
  def invalid_for_update?
    params[:id].to_i != @reservation.id ||
      @reservation.actual_end_at ||
      !editable_by_current_user?
  end

  def editable_by_current_user?
    if current_user.administrator? && @reservation.admin_editable?
      true
    elsif @reservation.can_customer_edit?
      true
    else
      false
    end
  end

  def save_reservation_and_order_detail
    @reservation.save_as_user!(session_user)
    @order_detail.assign_estimated_price(@reservation.reserve_end_at)
    @order_detail.save_as_user!(session_user)
  end

  def set_windows
    @max_window = max_reservation_window
    @max_days_ago = session_user.operator_of?(@facility) ? -365 : 0
    # initialize calendar time constraints
    @min_date     = (Time.zone.now + @max_days_ago.days).strftime("%Y%m%d")
    @max_date     = (Time.zone.now + @max_window.days).strftime("%Y%m%d")
  end

  def max_reservation_window
    return 365 if session_user.operator_of?(@facility)
    @reservation.longest_reservation_window(@order_detail.price_groups)
  end

  def notice_for_reservation(reservation)
    return unless reservation

    if reservation.can_switch_instrument_off? # do you need to click stop
      I18n.t("reservations.notices.can_switch_off", reservation: reservation)
    elsif reservation.can_switch_instrument_on? # do you need to begin your reservation
      I18n.t("reservations.notices.can_switch_on", reservation: reservation)
    elsif reservation.canceled?
    # no message
    # do you have a reservation for today that hasn't ended
    elsif upcoming_today? reservation
      I18n.t("reservations.notices.upcoming", reservation: reservation)
    end
  end

  def upcoming_today?(reservation)
    now = Time.zone.now
    (reservation.reserve_start_at.to_date == now.to_date || reservation.reserve_start_at < now) && reservation.reserve_end_at > now
  end

  def helpers
    ActionController::Base.helpers
  end

  def default_reservation_mins
    @instrument.min_reserve_mins.to_i > 0 ? @instrument.min_reserve_mins : 30
  end

  def default_reservation
    Reservation.new(product: @instrument,
                    reserve_start_at: Time.zone.now,
                    reserve_end_at: default_reservation_mins.minutes.from_now)
  end

  def month_view?
    # 1.week causes a problem with daylight saving week since it's technically longer
    # than a week
    @end_at - @start_at > 8.days
  end

  def render_edit
    set_windows
    render action: "edit"
  end

  def duration_change_valid?
    validator = Reservations::DurationChangeValidations.new(@reservation)
    validator.valid?
  end

end
