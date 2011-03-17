class ServicesController < ApplicationController
  customer_tab  :show
  admin_tab     :create, :destroy, :new, :edit, :index, :update, :manage
  before_filter :authenticate_user!, :except => [:show]
  before_filter :check_acting_as, :except => [:show]
  before_filter :init_current_facility
  before_filter :init_service, :except => [:index, :new, :create]

  load_and_authorize_resource :except => [:show]

  layout 'two_column'

  def initialize
    @active_tab = 'admin_products'
    super
  end

  # GET /services
  def index
    @archived_product_count     = current_facility.services.archived.length
    @not_archived_product_count = current_facility.services.not_archived.length
    @product_name               = 'Services'
    if params[:archived].nil? || params[:archived] != 'true'
      @services = current_facility.services.not_archived
    else
      @services = current_facility.services.archived
    end
  end

  # GET /services/1
  def show
    raise ActiveRecord::RecordNotFound if @service.is_archived? || (@service.is_hidden? && !acting_as?)
    @add_to_cart = true
    @log_in      = false

    # do the product have active price policies
    unless @service.can_purchase?
      @add_to_cart       = false
      flash.now[:notice] = 'This service is currently unavailable for purchase online.'
    end

    # is user logged in?
    if @add_to_cart && acting_user.nil?
      @log_in            = true
      @add_to_cart       = false
    end

    # is the user approved?
    if @add_to_cart && @service.requires_approval? && @service.product_users.find_by_user_id(acting_user.id).nil?
      @add_to_cart       = false
      flash.now[:notice] = 'This service requires approval to purchase; please contact the facility.'
    end

    # does the product have any price policies for any of the groups the user is a member of?
    if @add_to_cart && !(@service.can_purchase?((acting_user.price_groups + acting_user.account_price_groups).flatten.uniq.collect{ |pg| pg.id }))
      @add_to_cart       = false
      flash.now[:notice] = 'You are not in a price group that may reserve this service; please contact the facility.'
    end

    # when ordering on behalf of, does the staff have permissions for this facility?
    if @add_to_cart && acting_as? && !session_user.operator_of?(@service.facility)
      @add_to_cart = false
      flash.now[:notice] = 'You are not authorized to order services from this facility on behalf of a user.'
    end

    @active_tab = 'home'
    render :layout => 'application'
  end

  # GET /services/new
  def new
    @service = current_facility.services.new(:account => '75340')
  end

  # GET /services/1/edit
  def edit
  end

  # POST /services
  def create
    @service = current_facility.services.new(params[:service])
    @service.initial_order_status_id = OrderStatus.default_order_status.id
    
    if @service.save
      flash[:notice] = 'Service was successfully created.'
      redirect_to([:manage, current_facility, @service])
    else
      render :action => "new"
    end
  end

  # PUT /services/1
  def update
    respond_to do |format|
      if @service.update_attributes(params[:service])
        flash[:notice] = 'Service was successfully updated.'
        format.html { redirect_to(manage_facility_service_url(current_facility, @service)) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /services/1
  def destroy
    @service.destroy

    respond_to do |format|
      format.html { redirect_to(new_facility_service_url) }
    end
  end

  def manage
    @active_tab = 'admin_products'
  end

  def init_service
    @service = current_facility.services.find_by_url_name!(params[:service_id] || params[:id])
  end
end
