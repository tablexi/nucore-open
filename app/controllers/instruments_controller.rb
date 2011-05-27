class InstrumentsController < ApplicationController
  customer_tab  :show
  admin_tab     :agenda, :create, :edit, :index, :manage, :new, :schedule, :update
  before_filter :authenticate_user!, :except => :show
  before_filter :check_acting_as, :except => [:show]
  before_filter :init_current_facility
  before_filter :init_instrument, :except => [:index, :new, :create]

  load_and_authorize_resource :except => :show

  layout 'two_column'

  def initialize
    @active_tab = 'admin_products'
    super
  end

  # GET /instruments
  def index
    @archived_product_count     = current_facility.instruments.archived.length
    @not_archived_product_count = current_facility.instruments.not_archived.length
    @product_name               = 'Instruments'
    if params[:archived].nil? || params[:archived] != 'true'
      @instruments = current_facility.instruments.not_archived
    else
      @instruments = current_facility.instruments.archived
    end

    # find current and next upcoming reservations for each instrument
    @reservations = {}
    @instruments.each { |i| @reservations[i.id] = i.reservations.upcoming[0..2]}
    @instruments.sort!
  end

  # GET /instruments/1
  def show
    raise ActiveRecord::RecordNotFound if @instrument.is_archived? || (@instrument.is_hidden? && !acting_as?)
    @add_to_cart = true
    @login_required = false
    
    # do the product have active price policies && schedule rules
    unless @instrument.can_purchase?
      @add_to_cart       = false
      flash.now[:notice] = 'This instrument is currently unavailable for reservation online.'
    end

    # is user logged in?
    if @add_to_cart && acting_user.nil?
      @login_required = true
      @add_to_cart = false
    end

    # is the user approved?
    if @add_to_cart && !@instrument.is_approved_for?(acting_user)
      @add_to_cart       = false
      flash.now[:notice] = "This instrument requires approval to reserve; please contact the facility for further information:<br/><br/> #{@instrument.facility}<br/><a href=\"mailto:#{@instrument.facility.email}\">#{@instrument.facility.email}</a>"
    end

    # does the product have any price policies for any of the groups the user is a member of?
    if @add_to_cart && !(@instrument.can_purchase?((acting_user.price_groups + acting_user.account_price_groups).flatten.uniq.collect{ |pg| pg.id }))
      @add_to_cart       = false
      flash.now[:notice] = 'You are not in a price group that may reserve this instrument; please contact the facility.'
    end

    # when ordering on behalf of, does the staff have permissions for this facility?
    if @add_to_cart && acting_as? && !session_user.operator_of?(@instrument.facility)
      @add_to_cart = false
      flash.now[:notice] = 'You are not authorized to order instruments from this facility on behalf of a user.'
    end

    @active_tab = 'home'
    render :layout => 'application'
  end

  # GET /instruments/1/manage
  def manage
  end

  # GET /instruments/new
  def new
    @instrument = current_facility.instruments.new(:account => '75340')
  end

  # GET /items/1/edit
  def edit
  end

  # POST /instruments
  def create
    @instrument = current_facility.instruments.new(params[:instrument])
    @instrument.initial_order_status_id = OrderStatus.default_order_status.id
    
    if @instrument.save
      flash[:notice] = 'Instrument was successfully created.'
      redirect_to(manage_facility_instrument_url(current_facility, @instrument))
    else
      render :action => "new"
    end
  end

  # PUT /instruments/1
  def update
    @header_prefix = "Edit"
    
    respond_to do |format|
      if @instrument.update_attributes(params[:instrument])
        flash[:notice] = 'Instrument was successfully updated.'
        format.html { redirect_to(manage_facility_instrument_url(current_facility, @instrument)) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /instruments/1
  def destroy
    @instrument.destroy

    respond_to do |format|
      format.html { redirect_to(manage_facility_instrument_url(current_facility, @instrument)) }
    end
  end

  # GET /instruments/1/schedule
  def schedule
    @admin_reservations = @instrument.reservations.find(:all, :conditions => ['reserve_end_at > ? AND order_detail_id IS NULL', Time.zone.now])
  end

  # GET /instruments/1/agenda
  def agenda
  end

  # GET /facilities/:facility_id/instruments/:instrument_id/status
  def status
    begin
      @relay  = @instrument.relay_type.constantize.new(@instrument.relay_ip, @instrument.relay_username, @instrument.relay_password)
      status = Rails.env.test? ? true : @relay.get_status_port(@instrument.relay_port)
      @status = @instrument.instrument_statuses.create!(:is_on => status)
    rescue
      raise ActiveRecord::RecordNotFound
    end
    render :layout => false
  end

  # GET /facilities/:facility_id/instruments/:instrument_id/switch
  def switch
    raise ActiveRecord::RecordNotFound unless params[:switch] && (params[:switch] == 'on' || params[:switch] == 'off')

    begin
      relay = @instrument.relay_type.constantize.new(@instrument.relay_ip, @instrument.relay_username, @instrument.relay_password)
      status=true

      unless Rails.env.test?
        params[:switch] == 'on' ? relay.activate_port(@instrument.relay_port) : relay.deactivate_port(@instrument.relay_port)
        status = relay.get_status_port(@instrument.relay_port)
      end

      @status = @instrument.instrument_statuses.create!(:is_on => status)
    rescue
      raise ActiveRecord::RecordNotFound
    end
    render :action => :status, :layout => false
  end

  def init_instrument
    @instrument = current_facility.instruments.find_by_url_name!(params[:instrument_id] || params[:id])
  end
end
