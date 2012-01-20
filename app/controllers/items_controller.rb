class ItemsController < ApplicationController
  customer_tab  :show
  admin_tab     :create, :destroy, :new, :edit, :index, :update, :manage
  before_filter :authenticate_user!, :except => :show
  before_filter :check_acting_as, :except => [:show]
  before_filter :init_current_facility
  before_filter :init_item, :except => [:index, :new, :create]

  load_and_authorize_resource :except => :show

  layout 'two_column'

  include TranslationHelper
  
  def initialize
    @active_tab = 'admin_products'
    super
  end

  # GET /items
  def index
    @archived_product_count     = current_facility.items.archived.length
    @not_archived_product_count = current_facility.items.not_archived.length
    @product_name               = 'Items'
    if params[:archived].nil? || params[:archived] != 'true'
      @items = current_facility.items.not_archived
    else
      @items = current_facility.items.archived
    end

    @items.sort!
  end

  # GET /items/1
  def show
    raise ActiveRecord::RecordNotFound if @item.is_archived? || (@item.is_hidden? && !acting_as?)
    @add_to_cart = true
    @login_required = false

    # do the product have active price policies
    unless @item.can_purchase?
      @add_to_cart       = false
      flash.now[:notice] = t_model_error(Product, 'not_available')
    end

    # is user logged in?
    if @add_to_cart && acting_user.nil?
      @login_required = true
      @add_to_cart = false
    end

    # is the user approved?
    if @add_to_cart && !@item.is_approved_for?(acting_user)
      @add_to_cart       = false unless session_user and session_user.can_override_restrictions?(@item)
      flash.now[:notice] = t_model_error(Item, 'requires_approval').html_safe
    end

    # does the product have any price policies for any of the groups the user is a member of?
    if @add_to_cart && !(@item.can_purchase?((acting_user.price_groups + acting_user.account_price_groups).flatten.uniq.collect{ |pg| pg.id }))
      @add_to_cart       = false
      flash.now[:notice] = t_model_error(Item, 'not_in_price_group')
    end

    # when ordering on behalf of, does the staff have permissions for this facility?
    if @add_to_cart && acting_as? && !session_user.operator_of?(@item.facility)
      @add_to_cart = false
      flash.now[:notice] = t_model_error(Item, 'not_authorized_acting_as')
    end

    @active_tab = 'home'
    render :layout => 'application'
  end

  # GET /items/new
  def new
    @item = current_facility.items.new(:account => NUCore::COMMON_ACCOUNT)
  end

  # GET /facilities/alpha/items/1/edit
  def edit
  end

  # POST /facilities/alpha/items
  def create
    @item = current_facility.items.new(params[:item])
    @item.initial_order_status_id = OrderStatus.default_order_status.id
    
    if @item.save
      flash[:notice] = 'Item was successfully created.'
      redirect_to([:manage, current_facility, @item])
    else
      render :action => "new"
    end
  end

  # PUT /facilities/alpha/items/1
  def update
    if @item.update_attributes(params[:item])
      flash[:notice] = 'Item was successfully updated.'
      redirect_to manage_facility_item_url(current_facility, @item)
    else
      render :action => "edit"
    end
  end

  # DELETE /items/1
  def destroy
    @item.destroy
    redirect_to facility_items_url
  end

  # GET /facilities/alpha/items/1/manage
  def manage
    @active_tab = 'admin_products'
  end

  def init_item
    @item = current_facility.items.find_by_url_name!(params[:item_id] || params[:id])
  end
end
