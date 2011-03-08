class ReservationsController < ApplicationController
  customer_tab  :all
  before_filter :authenticate_user!
  before_filter :check_acting_as,  :except => [:new, :create, :edit, :update]
  
  def initialize
    @active_tab = 'orders'
    super
  end

  # GET /facilities/1/instruments/1/reservations.js?_=1279579838269&start=1279429200&end=1280034000
  def index
    @facility     = Facility.find_by_url_name!(params[:facility_id])
    @instrument   = @facility.instruments.find_by_url_name!(params[:instrument_id])
    @start_at     = params[:start] ? Time.zone.at(params[:start].to_i) : Time.zone.now
    @start_date   = @start_at.to_date
    @end_at       = params[:end] ? Time.zone.at(params[:end].to_i) : @start_at
    @reservations = @instrument.reservations.active
    @rules        = @instrument.schedule_rules
    
    if @end_at - @start_at <= 1.week
      # build unavailable schedule
      @unavailable = ScheduleRule.unavailable(@rules)
    else
      @unavailable = []
    end

    respond_to do |format|
      format.js { render :json => @reservations.map{|r| r.as_calendar_object(:start_date => @start_date)}.flatten + 
                                  @unavailable.map{|r| r.as_calendar_object(:start_date => @start_date)}.flatten }
    end
  end

  # POST /orders/1/order_details/1/reservations
  def create
    @order        = Order.find(params[:order_id])
    @order_detail = @order.order_details.find(params[:order_detail_id])
    @instrument   = @order_detail.product
    raise ActiveRecord::RecordNotFound unless @order_detail.reservation.nil?
    @reservation  = @instrument.reservations.new(params[:reservation].update(:order_detail => @order_detail))

    Reservation.transaction do
      @error = false
      if @reservation.valid?
        # find and add price policy
        groups = (@order.user.price_groups + @order.account.price_groups).flatten.uniq
        @cheapest_price_policy = @reservation.cheapest_price_policy(groups)
        @longest_reservation_window_price_policy = @reservation.longest_reservation_window_price_policy(groups)
        if @cheapest_price_policy.blank? || @longest_reservation_window_price_policy.blank?
          @error = true
          flash[:error] = "Unable to create a reservation at this time; no suitable price policies are available."
          raise ActiveRecord::Rollback
        else
          @order_detail.price_policy = @cheapest_price_policy
          costs = @cheapest_price_policy.estimate_cost_and_subsidy(@reservation.reserve_start_at, @reservation.reserve_end_at)
          @order_detail.estimated_cost    = costs[:cost]
          @order_detail.estimated_subsidy = costs[:subsidy]
        end
      end

      if @reservation.save && @order_detail.save
        flash[:notice] = 'Reservation was successfully created.'
      else
        @error = true
        raise ActiveRecord::Rollback
      end
    end

    respond_to do |format|
      if !@error
        format.html { redirect_to cart_url }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # GET /orders/1/order_details/1/reservations/new
  def new
    @order        = Order.find(params[:order_id])
    @order_detail = @order.order_details.find(params[:order_detail_id])
    @instrument   = @order_detail.product
    raise ActiveRecord::RecordNotFound unless @order_detail.reservation.nil?
    @reservation  = @instrument.next_available_reservation || Reservation.new(:duration_value => (@instrument.min_reserve_mins.to_i < 15 ? 15 : @instrument.min_reserve_mins), :duration_unit => 'minutes')

    groups = (@order.user.price_groups + @order.account.price_groups).flatten.uniq
    @pp_reservation = @reservation.longest_reservation_window_price_policy(groups)

    # initialize calendar time constraints
    @min_date     = Time.zone.now.strftime("%Y%m%d")
    @max_date     = (Time.zone.now + @pp_reservation.reservation_window.days).strftime("%Y%m%d")
  end

  # GET /orders/:order_id/order_details/:order_detail_id/reservations/:id(.:format)
  def show
    @order        = Order.find(params[:order_id])
    @order_detail = @order.order_details.find(params[:order_detail_id])
    @reservation  = Reservation.find(params[:id])
    
    raise ActiveRecord::RecordNotFound if (@reservation != @order_detail.reservation)
  end

  # GET /orders/1/order_details/1/reservations/1/edit
  def edit
    @order        = Order.find(params[:order_id])
    @order_detail = @order.order_details.find(params[:order_detail_id])
    @instrument   = @order_detail.product
    @reservation  = Reservation.find(params[:id])
    # TODO you shouldn't be able to edit reservations that have passed or are outside of the cancellation period (check to make sure order has been placed)
    raise ActiveRecord::RecordNotFound if (@reservation != @order_detail.reservation || @reservation.canceled_at || @reservation.actual_start_at || @reservation.actual_end_at)

    groups = (@order.user.price_groups + @order.account.price_groups).flatten.uniq
    @pp_reservation = @reservation.longest_reservation_window_price_policy(groups)

    # initialize calendar time constraints
    @min_date     = Time.zone.now.strftime("%Y%m%d")
    @max_date     = (Time.zone.now + @pp_reservation.reservation_window.days).strftime("%Y%m%d")
  end

  # PUT  /orders/1/order_details/1/reservations/1
  def update
    @order        = Order.find(params[:order_id])
    @order_detail = @order.order_details.find(params[:order_detail_id])
    @instrument   = @order_detail.product
    @reservation  = @instrument.reservations.find_by_id_and_order_detail_id!(params[:id], @order_detail.id)
    # TODO you shouldn't be able to edit reservations that have passed or are outside of the cancellation period (check to make sure order has been placed)
    raise ActiveRecord::RecordNotFound if (@reservation != @order_detail.reservation || @reservation.canceled_at || @reservation.actual_start_at || @reservation.actual_end_at)

    # clear existing reservation attributes
    [:reserve_start_at, :reserve_end_at].each do |k|
      @reservation.send("#{k}=", nil)
    end
    # set new reservation attributes
    params[:reservation].each_pair do |k, v|
      @reservation.send("#{k}=", v)
    end

    Reservation.transaction do
      @error = false
      if @reservation.valid?
        groups = (@order.user.price_groups + @order.account.price_groups).flatten.uniq
        @cheapest_price_policy = @reservation.cheapest_price_policy(groups)
        @longest_reservation_window_price_policy = @reservation.longest_reservation_window_price_policy(groups)
        if @cheapest_price_policy.blank? || @longest_reservation_window_price_policy.blank?
          @error = true
          flash[:error] = "Unable to create a reservation at this time; no suitable price policies are available."
          raise ActiveRecord::Rollback
        else
          @order_detail.price_policy = @cheapest_price_policy
          costs = @cheapest_price_policy.estimate_cost_and_subsidy(@reservation.reserve_start_at, @reservation.reserve_end_at)
          @order_detail.estimated_cost = costs[:cost]
          @order_detail.estimated_subsidy = costs[:subsidy]
        end
      end

      if @reservation.save && @order_detail.save
        flash[:notice] = 'Reservation was successfully updated.'
      else
        @error = true
        raise ActiveRecord::Rollback
      end
    end

    if !@error
      if @order.purchased?
        redirect_to orders_url
      else
        redirect_to cart_url
      end
    else
      render :action => "edit"
    end
  end
  
  # GET /orders/:order_id/order_details/:order_detail_id/reservations/switch_instrument
  def switch_instrument
    @order        = Order.find(params[:order_id])
    @order_detail = @order.order_details.find(params[:order_detail_id])
    @instrument   = @order_detail.product
    @reservation  = @instrument.reservations.find_by_id_and_order_detail_id(params[:reservation_id], @order_detail.id)
    raise ActiveRecord::RecordNotFound if @reservation.blank?
    raise ActiveRecord::RecordNotFound unless @order.user_id == session_user.id
    raise ActiveRecord::RecordNotFound unless params[:switch] && (params[:switch] == 'on' || params[:switch] == 'off')
    
    if (params[:switch] == 'on' && @reservation.can_switch_instrument_on?)
      @reservation.transaction do
        begin
          relay = Relay.new(@instrument.relay_ip, @instrument.relay_username, @instrument.relay_password)
          relay.activate_port(@instrument.relay_port)
          @reservation.actual_start_at = Time.zone.now
          @reservation.save!
          flash[:notice] = 'The instrument has been activated successfully'
          @instrument.instrument_statuses.create(:is_on => true)
        rescue Exception => e
          flash[:error] = 'An error was encounter while attempted to toggle the instrument.  Please try again.'
          raise ActiveRecord::Rollback
        end
      end
    elsif (params[:switch] == 'off' && @reservation.can_switch_instrument_off?)
      @reservation.transaction do
        begin
          relay = Relay.new(@instrument.relay_ip, @instrument.relay_username, @instrument.relay_password)
          # make sure no one else is using the instrument before killing power
          relay.deactivate_port(@instrument.relay_port) if @reservation.can_kill_power?
          @reservation.actual_end_at = Time.zone.now
          @reservation.save!
          costs = @order_detail.price_policy.calculate_actual_instrument_costs(@reservation)
          if costs
            @order_detail.actual_cost    = costs[:actual_cost]
            @order_detail.actual_subsidy = costs[:actual_subsidy]
          end
          @order_detail.change_status!(OrderStatus.find_by_name('Reviewable'))
          flash[:notice] = 'The instrument has been deactivated successfully'
          @instrument.instrument_statuses.create(:is_on => false)
        rescue Exception => e
          flash[:error] = 'An error was encounter while attempted to toggle the instrument.  Please try again.'
          raise ActiveRecord::Rollback
        end
      end
    else
      flash[:error] = 'An error was encounter while attempted to toggle the instrument.  Please try again.'
    end
    redirect_to request.referer || order_order_detail_path(@order, @order_detail)
  end
end