class BundlesController < ApplicationController
  customer_tab  :show
  admin_tab     :create, :destroy, :new, :edit, :index, :update, :manage
  before_filter :authenticate_user!, :except => :show
  before_filter :check_acting_as, :except => :show
  before_filter :init_current_facility
  before_filter :init_bundle, :except => [:index, :new, :create]

  load_and_authorize_resource :except => :show

  layout 'two_column'

  def initialize
    @active_tab = 'admin_products'
    super
  end

  # GET /bundles
  def index
    @archived_product_count     = current_facility.bundles.archived.length
    @not_archived_product_count = current_facility.bundles.not_archived.length
    @product_name               = 'Bundles'
    if params[:archived].nil? || params[:archived] != 'true'
      @bundles = current_facility.bundles.find(:all, :conditions => {'is_archived' => false})
    else
      @bundles = current_facility.bundles.archived
    end
  end

  # GET /bundles/:id
  def show
    raise ActiveRecord::RecordNotFound if @bundle.is_archived? || (@bundle.is_hidden? && !acting_as?)
    @add_to_cart = true
    @login_required = false

    # do the product have active price policies
    unless @bundle.can_purchase?
      @add_to_cart       = false
      flash.now[:notice] = 'This bundle is currently unavailable for purchase online.'
    end

    # is user logged in?
    if @add_to_cart && acting_user.nil?
      @login_required = true
      @add_to_cart = false
    end

    # is the user approved?
    if @add_to_cart && @bundle.requires_approval? && @bundle.product_users.find_by_user_id(acting_user.id).nil?
      @add_to_cart       = false
      flash.now[:notice] = 'This bundle requires approval to purchase; please contact the facility.'
    end

    # does the product have any price policies for any of the groups the user is a member of?
    if @add_to_cart && !(@bundle.can_purchase?((acting_user.price_groups + acting_user.account_price_groups).flatten.uniq.collect{ |pg| pg.id }))
      @add_to_cart       = false
      flash.now[:notice] = 'You are not in a price group that may purchase this bundle; please contact the facility.'
    end

    # when ordering on behalf of, does the staff have permissions for this facility?
    if @add_to_cart && acting_as? && !session_user.operator_of?(@bundle.facility)
      @add_to_cart = false
      flash.now[:notice] = 'You are not authorized to order bundles from this facility on behalf of a user.'
    end

    @active_tab = 'home'
    render :layout => 'application'
  end

  # GET /bundles/new
  def new
    @bundle = current_facility.bundles.new()
  end

  # GET /facilities/alpha/bundles/1/edit
  def edit
  end

  # POST /facilities/alpha/bundles
  def create
    @bundle = current_facility.bundles.new(params[:bundle])
    @bundle.initial_order_status_id = OrderStatus.default_order_status.id
    @bundle.requires_approval = false

    if @bundle.save
      flash[:notice] = 'The bundle was successfully created.'
      redirect_to([:manage, current_facility, @bundle])
    else
      render :action => "new"
    end
  end

  # PUT /facilities/alpha/bundles/1
  def update
    if @bundle.update_attributes(params[:bundle])
      flash[:notice] = 'The bundle was successfully updated.'
      redirect_to(manage_facility_bundle_url(current_facility, @bundle))
    else
      render :action => "edit"
    end
  end

  # GET /facilities/alpha/bundles/1/manage
  def manage
    @active_tab = 'admin_products'
  end

  def init_bundle
    @bundle = current_facility.bundles.find_by_url_name!(params[:bundle_id] || params[:id])
  end
end
