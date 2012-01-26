class ReservationsController < ApplicationController
  customer_tab  :all
  before_filter :authenticate_user!
  before_filter :check_acting_as,  :only => [ :switch_instrument, :show, :list]
  before_filter :load_basic_resources, :only => [:new, :create, :edit, :update]
  before_filter :load_and_check_resources, :only => [ :move, :switch_instrument ]

  include TranslationHelper
  
  def initialize
    super
    @active_tab = 'reservations'
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
      as_calendar_object_options = {:start_date => @start_date, :with_details => params[:with_details]}
      format.js { render :json => @reservations.map{|r| r.as_calendar_object(as_calendar_object_options)}.flatten + 
                                  @unavailable.map{ |r| r.as_calendar_object(as_calendar_object_options)}.flatten }
    end
  end

  # GET /reservations
  # All My Resesrvations
  def list
    notices = []
    now = Time.zone.now
    @available_statuses = ['upcoming', 'all']
    case params[:status]
    when 'upcoming'
      @order_details = current_user.order_details.upcoming_reservations
    when 'all'
      @order_details = current_user.order_details.all_reservations
    else
      redirect_to reservations_status_path(:status => "upcoming")
      return
    end
    @order_details = @order_details.paginate(:page => params[:page])
    
      # joins(:order).
      # includes(:reservation).
      # where("orders.ordered_at IS NOT NULL").
      # order('orders.ordered_at DESC').all

    #@order_details=@order_details.delete_if{|od| od.reservation.nil? }.paginate(:page => params[:page])

    @order_details.each do |od|
      res = od.reservation
      # do you need to click stop
      if res.can_switch_instrument_off?
        notices << "Do not forget to click the \"End Reservation\" link when you finished your #{res} reservation."
      # do you need to begin your reservation
      elsif res.can_switch_instrument_on?
        notices << "You may click the \"Begin Reservation\" link when you are ready to begin your #{res} reservation."
      # do you have a reservation for today
      elsif (res.reserve_start_at.to_s[0..9] == now.to_s[0..9] || res.reserve_start_at < now) && res.reserve_end_at > now
        notices << "You have an upcoming reservation for #{res}."
      end
    end

    flash.now[:notice] = notices.join('<br />').html_safe unless notices.empty?
  end

  # POST /orders/1/order_details/1/reservations
  def create
    raise ActiveRecord::RecordNotFound unless @reservation.nil?
    @reservation  = @instrument.reservations.new(params[:reservation].update(:order_detail => @order_detail))
    
    if !@order_detail.bundled? && params[:order_account].blank?
      flash[:error]=I18n.t 'controllers.reservations.create.no_selection'
      return redirect_to new_order_order_detail_reservation_path(@order, @order_detail)
    end

    Reservation.transaction do
      begin
        unless params[:order_account].blank?
          account=Account.find(params[:order_account].to_i)
          if account != @order.account
            @order.invalidate
            @order.update_attributes!(:account_id => account.id)
            @order_detail.update_account(account)
            @order_detail.save!
          end
        end
        @reservation.save_as_user!(session_user)
        
        groups = (@order.user.price_groups + @order.account.price_groups).flatten.uniq
        @cheapest_price_policy = @reservation.cheapest_price_policy(groups)
        if @cheapest_price_policy
          costs = @cheapest_price_policy.estimate_cost_and_subsidy(@reservation.reserve_start_at, @reservation.reserve_end_at)
          @order_detail.estimated_cost    = costs[:cost]
          @order_detail.estimated_subsidy = costs[:subsidy]
          @order_detail.save!
        end
        flash[:notice] = I18n.t 'controllers.reservations.create.success'

        if @order_detail.product.is_a?(Instrument) && !@order_detail.bundled?
          redirect_to purchase_order_path(@order)
        else
          redirect_to cart_path
        end

        return
      rescue Exception => e
        raise ActiveRecord::Rollback
      end
    end
    render :action => "new"
  end

  # GET /orders/1/order_details/1/reservations/new
  def new
    raise ActiveRecord::RecordNotFound unless @reservation.nil?
    @reservation  = @instrument.next_available_reservation || Reservation.new(:instrument => @instrument, :duration_value => (@instrument.min_reserve_mins.to_i < 15 ? 15 : @instrument.min_reserve_mins), :duration_unit => 'minutes')
    flash[:notice] = t_model_error(Instrument, 'acting_as_not_on_approval_list') unless @instrument.is_approved_for?(acting_user)
    set_windows
    
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
    # TODO you shouldn't be able to edit reservations that have passed or are outside of the cancellation period (check to make sure order has been placed)
    raise ActiveRecord::RecordNotFound if (params[:id].to_i != @reservation.id || @reservation.canceled_at || @reservation.actual_start_at || @reservation.actual_end_at)
    set_windows
  end

  # PUT  /orders/1/order_details/1/reservations/1
  def update
    # TODO you shouldn't be able to edit reservations that have passed or are outside of the cancellation period (check to make sure order has been placed)
    raise ActiveRecord::RecordNotFound if (params[:id].to_i != @reservation.id || @reservation.canceled_at || @reservation.actual_start_at || @reservation.actual_end_at)

    # clear existing reservation attributes
    [:reserve_start_at, :reserve_end_at].each do |k|
      @reservation.send("#{k}=", nil)
    end
    # set new reservation attributes
    params[:reservation].each_pair do |k, v|
      @reservation.send("#{k}=", v)
    end


    Reservation.transaction do
      begin
        @reservation.save_as_user!(session_user)
        groups = (@order.user.price_groups + @order.account.price_groups).flatten.uniq
        @cheapest_price_policy = @reservation.cheapest_price_policy(groups)
        if @cheapest_price_policy
          costs = @cheapest_price_policy.estimate_cost_and_subsidy(@reservation.reserve_start_at, @reservation.reserve_end_at)
          @order_detail.estimated_cost    = costs[:cost]
          @order_detail.estimated_subsidy = costs[:subsidy]
          @order_detail.save!
        end
        flash[:notice] = 'The reservation was successfully updated.'
        redirect_to (@order.purchased? ? reservations_path : cart_path) and return
      rescue Exception => e
        raise ActiveRecord::Rollback
      end
    end
    render :action => "edit"
  end

  # GET /orders/:order_id/order_details/:order_detail_id/reservations/:reservation_id/move
  # this action should really respond to a PUT only but for some reason that doesn't work w/ jQuery UI popup
  def move
    earlier=@reservation.earliest_possible

    unless earlier
      flash[:notice]='Sorry, but your reservation can no longer be moved.'
    else
      begin
        @reservation.move_to!(earlier)
        flash[:notice]='The reservation was moved successfully.'
      rescue => e
        flash[:error]='Sorry, but your reservation could not be moved. Please try again later.'
        Rails.logger.error(e.backtrace.join("\n"))
      end
    end

    return redirect_to reservations_path
  end

  # GET /orders/:order_id/order_details/:order_detail_id/reservations/switch_instrument
  def switch_instrument
    relay_error_msg = 'An error was encountered while attempted to toggle the instrument. Please try again.'
    raise ActiveRecord::RecordNotFound unless params[:switch] && (params[:switch] == 'on' || params[:switch] == 'off')
    
    begin
      relay = @instrument.relay
      if (params[:switch] == 'on' && @reservation.can_switch_instrument_on?)
        status=Rails.env.production? ? nil : true

        if status.nil?
          port=@instrument.relay.port
          relay.activate_port(port)
          status = relay.get_status_port(port)
        end

        if status
          @reservation.actual_start_at = Time.zone.now
          @reservation.save!
          flash[:notice] = 'The instrument has been activated successfully'
        else
          raise Exception
        end
        @instrument.instrument_statuses.create(:is_on => status)
      elsif (params[:switch] == 'off' && @reservation.can_switch_instrument_off?)
        status=Rails.env.production? ? nil : false

        if status.nil?
          port=@instrument.relay.port
          relay.deactivate_port(port)
          status = relay.get_status_port(port)
        end

        if status == false
          @reservation.actual_end_at = Time.zone.now
          @reservation.save!
          flash[:notice] = 'The instrument has been deactivated successfully'
        else
          raise Exception
        end
        @instrument.instrument_statuses.create(:is_on => status)

        # reservation is done, now give the best price
        @reservation.order_detail.assign_price_policy
        @reservation.order_detail.save!
      else
        raise Exception
      end
    rescue Exception => e
      flash[:error] = relay_error_msg
    end

    redirect_to params[:redirect_to] || request.referer || order_order_detail_path(@order, @order_detail)
  end


  private
  def load_basic_resources
    @order_detail = Order.find(params[:order_id]).order_details.find(params[:order_detail_id])
    @order = @order_detail.order
    @reservation = @order_detail.reservation
    @instrument   = @order_detail.product
    @facility = @instrument.facility
  end
  def load_and_check_resources
    load_basic_resources
    #@reservation  = @instrument.reservations.find_by_id_and_order_detail_id(params[:reservation_id], @order_detail.id)
    raise ActiveRecord::RecordNotFound if @reservation.blank?
    raise ActiveRecord::RecordNotFound unless @order.user_id == session_user.id
  end
  def set_windows
    groups = (@order.user.price_groups + @order.account.price_groups).flatten.uniq
    @max_window = session_user.operator_of?(@facility) ? 365 : @reservation.longest_reservation_window(groups)
    @max_days_ago = session_user.operator_of?(@facility) ? -365 : 0
    # initialize calendar time constraints
    @min_date     = (Time.zone.now + @max_days_ago.days).strftime("%Y%m%d")
    @max_date     = (Time.zone.now + @max_window.days).strftime("%Y%m%d")
  end

end
