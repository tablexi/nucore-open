class FacilityReservationsController < ApplicationController

  include ProblemOrderDetailsController
  include TabCountHelper
  include Timelineable

  admin_tab     :all
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_current_facility

  load_and_authorize_resource class: Reservation

  helper_method :sort_column, :sort_direction

  ORDER_BY_CLAUSE_OVERRIDES_BY_SORTABLE_COLUMN = {
    "date" => "reservations.reserve_start_at",
    "reserve_range" => "CONCAT(reservations.reserve_start_at, reservations.reserve_end_at)",
    "product_name"  => "products.name",
    "status"        => "order_statuses.name",
    "assigned_to"   => "CONCAT(assigned_users_order_details.last_name, assigned_users_order_details.first_name)",
    "reserved_by"   => "#{User.table_name}.first_name, #{User.table_name}.last_name",
  }.freeze

  def initialize
    super
    @active_tab = "admin_reservations"
  end

  # GET /facilities/:facility_id/reservations
  def index
    real_sort_clause = ORDER_BY_CLAUSE_OVERRIDES_BY_SORTABLE_COLUMN[sort_column] || sort_column

    order_by_clause = [real_sort_clause, sort_direction].join(" ")
    @order_details = new_or_in_process_orders(order_by_clause)

    @order_details = @order_details.paginate(page: params[:page])
  end

  # GET /facilities/:facility_id/orders/:order_id/order_details/:order_detail_id/reservations/:id/edit
  def edit
    @order        = Order.find(params[:order_id])
    @order_detail = @order.order_details.find(params[:order_detail_id])
    @reservation  = @order_detail.reservation
    @instrument   = @order_detail.product

    raise ActiveRecord::RecordNotFound unless @reservation == Reservation.find(params[:id])
    set_windows
    if @reservation.locked?
      return redirect_to facility_order_order_detail_reservation_path(current_facility, @order, @order_detail, @reservation)
    end
  end

  # PUT /facilities/:facility_id/orders/:order_id/order_details/:order_detail_id/reservations/:id
  def update
    @order        = Order.find(params[:order_id])
    @order_detail = @order.order_details.find(params[:order_detail_id])
    @reservation  = @order_detail.reservation
    @instrument   = @order_detail.product
    if @reservation != Reservation.find(params[:id]) || @reservation.locked?
      raise ActiveRecord::RecordNotFound
    end
    set_windows

    @reservation.assign_times_from_params(params[:reservation])

    additional_notice = ""

    if @order_detail.price_policy
      update_prices

      if @order_detail.actual_cost_changed? || @order_detail.actual_subsidy_changed?
        additional_notice = "  Order detail actual cost has been updated as well."
      end
    else
      # We're updating a reservation before it's been completed
      if reserve_changed?
        @order_detail.assign_estimated_price
        additional_notice = " Estimated cost has been updated as well."
      end
    end

    Reservation.transaction do
      begin
        @reservation.save_as_user!(session_user)

        unless @order_detail.price_policy
          old_pp = @order_detail.price_policy

          @order_detail.assign_price_policy
          additional_notice = "  Order detail price policy and actual cost have been updated as well." unless old_pp == @order_detail.price_policy
        end
        @order_detail.save!
        flash.now[:notice] = "The reservation has been updated successfully.#{additional_notice}"
      rescue
        flash.now[:error] = "An error was encountered while updating the reservation."
        raise ActiveRecord::Rollback
      end
    end

    render action: "edit"
  end

  # GET /facilities/:facility_id/orders/:order_id/order_details/:order_detail_id/reservations/:id
  def show
    @order        = Order.find(params[:order_id])
    @order_detail = OrderDetail.find(params[:order_detail_id])
    @reservation  = @order_detail.reservation
    @instrument   = @order_detail.product
  end

  # GET /facilities/:facility_id/instruments/:instrument_id/reservations/new
  def new
    @instrument   = current_facility.instruments.find_by_url_name!(params[:instrument_id])
    @reservation = @instrument.next_available_reservation ||
                   @instrument.admin_reservations.build(duration_mins: @instrument.min_reserve_mins)
    @reservation = @reservation.becomes(AdminReservation)
    @reservation.round_reservation_times
    set_windows

    render layout: "two_column"
  end

  # POST /facilities/:facility_id/instruments/:instrument_id/reservations
  def create
    @instrument =
      current_facility.instruments.find_by!(url_name: params[:instrument_id])
    @reservation = @instrument.admin_reservations.new
    @reservation.assign_attributes(params[:admin_reservation])
    @reservation.assign_times_from_params(params[:admin_reservation])

    if @reservation.save
      flash[:notice] = "The reservation has been created successfully."
      redirect_to facility_instrument_schedule_url
    else
      set_windows
      render action: "new", layout: "two_column"
    end
  end

  # GET /facilities/:facility_id/instruments/:instrument_id/reservations/:id/edit_admin
  def edit_admin
    @instrument  = current_facility.instruments.find_by_url_name!(params[:instrument_id])
    @reservation = @instrument.reservations.find(params[:reservation_id])
    raise ActiveRecord::RecordNotFound unless @reservation.order_detail_id.nil?
    set_windows
    render layout: "two_column"
  end

  # PUT /facilities/:facility_id/instruments/:instrument_id/reservations/:id
  def update_admin
    @instrument  = current_facility.instruments.find_by_url_name!(params[:instrument_id])
    @reservation = @instrument.reservations.find(params[:reservation_id])
    raise ActiveRecord::RecordNotFound unless @reservation.order_detail_id.nil?
    set_windows

    @reservation.assign_times_from_params(params[:admin_reservation])
    @reservation.admin_note = params[:admin_reservation][:admin_note]
    @reservation.category = params[:admin_reservation][:category]

    if @reservation.save
      flash[:notice] = "The reservation has been updated successfully."
      redirect_to facility_instrument_schedule_url
    else
      render action: "edit_admin", layout: "two_column"
    end
  end

  # POST /facilities/:facility_id/reservations/batch_update
  def batch_update
    redirect_to facility_reservations_path

    msg_hash = batch_updater.update!

    # add flash messages if necessary
    flash.merge!(msg_hash) if msg_hash
  end

  # GET /facilities/:facility_id/reservations/disputed
  def disputed
    @order_details = disputed_orders
                     .paginate(page: params[:page])
  end

  # DELETE  /facilities/:facility_id/instruments/:instrument_id/reservations/:id
  def destroy
    @instrument  = current_facility.instruments.find_by_url_name!(params[:instrument_id])
    @reservation = @instrument.reservations.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @reservation.order_detail_id.nil?

    @reservation.destroy
    flash[:notice] = "The reservation has been removed successfully"
    redirect_to facility_instrument_schedule_url
  end

  protected

  def show_problems_path
    show_problems_facility_reservations_path
  end

  private

  def batch_updater
    @batch_updater ||= OrderDetailBatchUpdater.new(params[:order_detail_ids], current_facility, session_user, params, "reservations")
  end

  def reserve_changed?
    @reservation.admin_editable? &&
      (@reservation.reserve_start_at_changed? || @reservation.reserve_end_at_changed?)
  end

  def actual_changed?
    @reservation.can_edit_actuals? &&
      (@reservation.actual_start_at_changed? || @reservation.actual_end_at_changed?)
  end

  def update_prices
    if reserve_changed? || actual_changed?
      @order_detail.assign_estimated_price_from_policy(@order_detail.price_policy)

      costs = @order_detail.price_policy.calculate_cost_and_subsidy(@reservation)
      if costs.present?
        @order_detail.actual_cost    = costs[:cost]
        @order_detail.actual_subsidy = costs[:subsidy]
      end
    end
  end

  def new_or_in_process_orders(order_by_clause = "reservations.reserve_start_at")
    current_facility.order_details.new_or_inprocess.reservations
                    .includes(
                      { order: :user },
                      :order_status,
                      :reservation,
                      :assigned_user,
                    )
                    .where("reservations.id IS NOT NULL")
                    .order(order_by_clause)
  end

  def problem_order_details
    current_facility
      .problem_reservation_order_details
      .joins(:reservation)
      .order("reservations.reserve_start_at DESC")
  end

  def disputed_orders
    current_facility.order_details
                    .reservations
                    .in_dispute
  end

  def sort_column
    # TK: check against a whitelist
    params[:sort] || "date"
  end

  def sort_direction
    (params[:dir] || "") =~ /asc/i ? "asc" : "desc"
  end

  def set_windows
    @max_window = 365
    @max_days_ago = -365
    # initialize calendar time constraints
    @min_date     = Time.zone.now.strftime("%Y%m%d")
    @max_date     = (Time.zone.now + @max_window.days).strftime("%Y%m%d")
  end

end
