class FacilityReservationsController < ApplicationController
  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility

  load_and_authorize_resource :class => Reservation

  helper_method :sort_column, :sort_direction
  helper_method :new_or_in_process_orders, :problem_orders, :disputed_orders

  ORDER_BY_CLAUSE_OVERRIDES_BY_SORTABLE_COLUMN = {
      'date'          => 'reservations.reserve_start_at',
      'reserve_range' => 'CONCAT(reservations.reserve_start_at, reservations.reserve_end_at)',
      'product_name'  => 'products.name',
      'status'        => 'order_statuses.name',
      'assigned_to'   => "CONCAT(assigned_users_order_details.last_name, assigned_users_order_details.first_name)",
      'reserved_by'   => "#{User.table_name}.first_name, #{User.table_name}.last_name"
  }


  def initialize
    super
    @active_tab = 'admin_reservations'
  end

  # GET /facilities/:facility_id/reservations
  def index
    real_sort_clause = ORDER_BY_CLAUSE_OVERRIDES_BY_SORTABLE_COLUMN[sort_column] || sort_column

    order_by_clause = [real_sort_clause, sort_direction].join(' ')
    @order_details = new_or_in_process_orders(order_by_clause)

    @order_details=@order_details.paginate(:page => params[:page])
  end

  # GET /facilities/:facility_id/orders/:order_id/order_details/:order_detail_id/reservations/:id/edit
  def edit
    @order        = Order.find(params[:order_id])
    @order_detail = @order.order_details.find(params[:order_detail_id])
    @reservation  = @order_detail.reservation
    @instrument   = @order_detail.product

    raise ActiveRecord::RecordNotFound unless @reservation == Reservation.find(params[:id])

    unless @reservation.can_edit? || @reservation.can_edit_actuals?
      return redirect_to facility_order_order_detail_reservation_path(current_facility, @order, @order_detail, @reservation)
    end
  end

  # PUT /facilities/:facility_id/orders/:order_id/order_details/:order_detail_id/reservations/:id
  def update
    @order        = Order.find(params[:order_id])
    @order_detail = @order.order_details.find(params[:order_detail_id])
    @reservation  = @order_detail.reservation
    @instrument   = @order_detail.product
    raise ActiveRecord::RecordNotFound unless @reservation == Reservation.find(params[:id]) && (@reservation.can_edit? || @reservation.can_edit_actuals?)

    # clear existing reservation attributes
    can_edit_reserve = @reservation.can_edit?
    can_edit_actuals = @reservation.can_edit_actuals?
    if can_edit_reserve
      [:reserve_start_at, :reserve_end_at].each do |k|
        @reservation.send("#{k}=", nil)
      end
    end

    # clear existing actuals attributes
    if can_edit_actuals
      [:actual_start_at, :actual_end_at].each do |k|
        @reservation.send("#{k}=", nil)
      end
    end

    # set new reservation attributes
    params[:reservation].each_pair do |k, v|
      @reservation.send("#{k}=", v)
    end

    additional_notice = ''
    @reservation.set_all_split_times

    if @order_detail.price_policy
      if can_edit_reserve && @reservation.changes.any? { |k,v| k == 'reserve_start_at' || k == 'reserve_end_at' }
        costs = @order_detail.price_policy.estimate_cost_and_subsidy(@reservation.reserve_start_at, @reservation.reserve_end_at)
        if costs
          @order_detail.estimated_cost    = costs[:cost]
          @order_detail.estimated_subsidy = costs[:subsidy]
          additional_notice = '  Order detail cost estimate has been updated as well.'
        end
      elsif can_edit_actuals && @reservation.changes.any? { |k,v| k == 'actual_start_at' || k == 'actual_end_at' }
        costs = @order_detail.price_policy.calculate_cost_and_subsidy(@reservation)
        if costs
          @order_detail.actual_cost    = costs[:cost]
          @order_detail.actual_subsidy = costs[:subsidy]
          additional_notice = '  Order detail actual cost has been updated as well.'
        end
      end
    end

    Reservation.transaction do
      begin
        @reservation.save!

        unless @order_detail.price_policy
          @order_detail.assign_price_policy
          additional_notice = '  Order detail price policy and actual cost has been updated as well.'
        end

        @order_detail.save!
        flash.now[:notice] = "The reservation has been updated successfully.#{additional_notice}"
      rescue
        flash.now[:error] = "An error was encountered while updating the reservation."
        raise ActiveRecord::Rollback
      end
    end

    render :action => "edit"
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
    @reservation  = @instrument.next_available_reservation || Reservation.new(:duration_value => @instrument.min_reserve_mins, :duration_unit => 'minutes')

    # initialize calendar time constraints
    @min_date     = Time.zone.now.strftime("%Y%m%d")
    @max_date     = (Time.zone.now + @instrument.max_reservation_window.days).strftime("%Y%m%d")

    render :layout => 'two_column'
  end

  # POST /facilities/:facility_id/instruments/:instrument_id/reservations
  def create
    @instrument   = current_facility.instruments.find_by_url_name!(params[:instrument_id])
    @reservation  = @instrument.reservations.new(params[:reservation])

    if @reservation.save
      flash[:notice] = 'The reservation has been created successfully.'
      redirect_to facility_instrument_schedule_url
    else
      render :action => "new", :layout => 'two_column'
    end
  end

  # GET /facilities/:facility_id/instruments/:instrument_id/reservations/:id/edit_admin
  def edit_admin
    @instrument  = current_facility.instruments.find_by_url_name!(params[:instrument_id])
    @reservation = @instrument.reservations.find(params[:reservation_id])
    raise ActiveRecord::RecordNotFound unless @reservation.order_detail_id.nil?

    render :layout => 'two_column'
  end

  # PUT /facilities/:facility_id/instruments/:instrument_id/reservations/:id
  def update_admin
    @instrument  = current_facility.instruments.find_by_url_name!(params[:instrument_id])
    @reservation = @instrument.reservations.find(params[:reservation_id])
    raise ActiveRecord::RecordNotFound unless @reservation.order_detail_id.nil?

    [:reserve_start_at, :reserve_end_at].each do |k|
      @reservation.send("#{k}=", nil)
    end

    # set new reservation attributes
    params[:reservation].each_pair do |k, v|
      @reservation.send("#{k}=", v)
    end
    @reservation.set_all_split_times

    if @reservation.save
      flash[:notice] = 'The reservation has been updated successfully.'
      redirect_to facility_instrument_schedule_url
    else
      render :action => "edit_admin", :layout => 'two_column'
    end
  end

  # POST /facilities/:facility_id/reservations/batch_update
  def batch_update 
    redirect_to facility_reservations_path

    msg_hash = OrderDetail.batch_update(params[:order_detail_ids], current_facility, session_user, params, 'reservations')

    # add flash messages if necessary
    if msg_hash
      flash.merge!(msg_hash)
    end
  end

  # GET /facilities/:facility_id/orders/review
  def show_problems
    @order_details = problem_orders.
      paginate(:page => params[:page])
  end

  # GET /facilities/:facility_id/orders/disputed
  def disputed
    @details = disputed_orders.
      paginate(:page => params[:page])
  end

  # DELETE  /facilities/:facility_id/instruments/:instrument_id/reservations/:id
  def destroy
    @instrument  = current_facility.instruments.find_by_url_name!(params[:instrument_id])
    @reservation = @instrument.reservations.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @reservation.order_detail_id.nil?

    @reservation.destroy
    flash[:notice] = 'The reservation has been removed successfully'
    redirect_to facility_instrument_schedule_url
  end

  private

  def new_or_in_process_orders(order_by_clause = 'reservations.reserve_start_at')
    current_facility.order_details.new_or_inprocess.reservations.
      includes(
        {:order => :user},
        :order_status,
        :reservation,
        :assigned_user
      ).
      order(order_by_clause).
      delete_if{|od| od.reservation.nil? }
  end
  
  def problem_orders
    current_facility.order_details.
      reservations.
      reject{|od| !od.problem_order?}
  end
  def disputed_orders
    current_facility.order_details.
      reservations.
      in_dispute
  end
  def sort_column
    # TK: check against a whitelist
    params[:sort] || 'date'
  end

  def sort_direction
    (params[:dir] || '') =~ /asc/i ? 'asc' : 'desc'
  end
end
