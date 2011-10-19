class FacilitiesController < ApplicationController
  customer_tab  :index, :list, :show
  admin_tab     :edit, :manage, :schedule, :update, :agenda
  before_filter :authenticate_user!, :except => [:index, :show]  # public pages do not require authentication
  before_filter :check_acting_as, :except => [:index, :show]
  before_filter :init_current_facility, :only => [:edit, :manage, :schedule, :show, :update, :agenda]

  load_resource :find_by => :url_name
  authorize_resource
  skip_load_and_authorize_resource :only => [:index, :show]

  layout 'two_column'

  # GET /facilities
  def index
    @facilities = Facility.active
    @active_tab = 'home'
    render :layout => 'application'
  end

  # GET /facilities/abc123
  def show
    raise ActiveRecord::RecordNotFound unless current_facility.is_active?
    @active_tab = 'home'
    render :layout => 'application'
  end

  # GET /facilities/list
  def list
    # show list of manageable facilities for current user, and admins manage all facilities
    @active_tab = 'manage_facilites'
    if session_user.administrator?
      @facilities = Facility.all
      flash.now[:notice] = "No facilities have been added" if @facilities.empty?
    else
      @facilities = manageable_facilities
      raise ActiveRecord::RecordNotFound if @facilities.empty?
      if (@facilities.size == 1)
        redirect_to facility_orders_path(@facilities[0]) 
        return
      end
    end

    render :layout => 'application'
  end

  # GET /facilities/1/manage
  def manage
    @active_tab = 'admin_facility'
  end

  # GET /facilities/new
  def new
    @active_tab = 'manage_facilites'
    @facility = Facility.new
    @facility.is_active = true

    render :layout => 'application'
  end

  # GET /facilities/1/edit
  def edit
    @active_tab = 'admin_facility'
  end

  # POST /facilities
  def create
    @active_tab = 'manage_facilites'
    @facility = Facility.new(params[:facility])

    if @facility.save
      flash[:notice] = 'The facility was successfully created.'
      redirect_to manage_facility_url(@facility)
    else
      render :action => "new", :layout => 'application'
    end
  end

  # PUT /facilities/abc123
  def update
    if current_facility.update_attributes(params[:facility])
      flash[:notice] = 'The facility was successfully updated.'
      redirect_to manage_facility_url(current_facility)
    else
      render :action => "edit"
    end
  end

  def schedule
    @active_tab = 'admin_products'
    render :layout => 'product'
  end

  def agenda
    @active_tab = 'admin_products'
    render :layout => 'product'
  end
end
