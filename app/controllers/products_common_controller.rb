class ProductsCommonController < ApplicationController
  customer_tab  :show
  admin_tab     :create, :destroy, :new, :edit, :index, :update, :manage
  before_filter :authenticate_user!, :except => [:show]
  before_filter :check_acting_as, :except => [:show]
  before_filter :init_current_facility
  before_filter :init_product, :except => [:index, :new, :create]

  include TranslationHelper
  load_and_authorize_resource :except => [:show, :manage]

  layout 'two_column'

  def initialize
    @active_tab = 'admin_products'
    super
  end

  # GET /services
  def index
    @product_name = self.class.name.gsub(/Controller$/, '')

    @archived_product_count     = current_facility_products.archived.length
    @not_archived_product_count = current_facility_products.not_archived.length
    if params[:archived].nil? || params[:archived] != 'true'
      @products = current_facility_products.not_archived
    else
      @products = current_facility_products.archived
    end

    # not sure this actually does anything since @products is a Relation, not an Array, but it was
    # in ServicesController, ItemsController, and InstrumentsController before I pulled #index up
    # into this class
    @products.sort!

    # save to @services, @items, etc.
    instance_variable_set("@#{plural_object_name}", @products)
  end

  # GET /(services|items|instruments|bundles)/1
  def show
    assert_product_is_accessible!
    @add_to_cart = true
    @login_required = false

    # do the product have active price policies
    unless @product.available_for_purchase?
      @add_to_cart       = false
      @error = 'not_available'
    end

    # is user logged in?
    if @add_to_cart && acting_user.nil?
      @login_required = true
      @add_to_cart = false
    end

    # when ordering on behalf of, does the staff have permissions for this facility?
    if @add_to_cart && acting_as? && !session_user.operator_of?(@product.facility)
      @add_to_cart = false
      @error = 'not_authorized_acting_as'
    end

    # does the user have a valid payment source for purchasing this reservation?
    if @add_to_cart && acting_user.accounts_for_product(@product).blank?
      @add_to_cart=false
      @error='no_accounts'
    end

    # does the product have any price policies for any of the groups the user is a member of?
    if @add_to_cart && !price_policy_available_for_product?
      @add_to_cart       = false
      @error = 'not_in_price_group'
    end

    # is the user approved?
    if @add_to_cart && !@product.is_approved_for?(acting_user)
      @add_to_cart       = false unless session_user and session_user.can_override_restrictions?(@product)
      @error = 'requires_approval'
    end

    flash.now[:notice] = t_model_error(@product.class, @error) if @error

    @active_tab = 'home'
    render :layout => 'application'
  end

  # GET /services/new
  def new
    @product = current_facility_products.new(:account => NUCore::COMMON_ACCOUNT)
    save_product_into_object_name_instance
  end

  # POST /services
  def create
    @product = current_facility_products.new(params[:"#{singular_object_name}"])
    @product.initial_order_status_id = OrderStatus.default_order_status.id

    save_product_into_object_name_instance

    if @product.save
      flash[:notice] = "#{@product.class.name} was successfully created."
      redirect_to([:manage, current_facility, @product])
    else
      render :action => "new"
    end
  end

  # GET /facilities/alpha/(items|services|instruments)/1/edit
  def edit
  end

  # PUT /services/1
  def update
    respond_to do |format|
      if @product.update_attributes(params[:"#{singular_object_name}"])
        flash[:notice] = "#{@product.class.name.capitalize} was successfully updated."
        format.html { redirect_to([:manage, current_facility, @product]) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /services/1
  def destroy
    if @product.destroy
      flash[:notice] = "#{@product.class.name} was successfully deleted"
    else
      flash[:error] = "There was a problem deleting the #{@product.class.name.to_lower}"
    end
    redirect_to [current_facility, plural_object_name]
  end

  def manage
    authorize! :view_details, @product
    @active_tab = 'admin_products'
  end

  private

  def assert_product_is_accessible!
    raise NUCore::PermissionDenied unless product_is_accessible?
  end

  def product_is_accessible?
    is_operator = session_user && session_user.operator_of?(current_facility)
    !(@product.is_archived? || (@product.is_hidden? && !is_operator))
  end
  # The equivalent of calling current_facility.services or current_facility.items
  def current_facility_products
    return current_facility.send(:"#{plural_object_name}")
  end

  def price_policy_available_for_product?
    groups = (acting_user.price_groups + acting_user.account_price_groups).flatten.uniq.collect{ |pg| pg.id }
    @product.can_purchase?(groups)
  end

  # Dynamically get the proper object from the database based on the controller name
  def init_product
    @product = current_facility_products.find_by_url_name!(params[:"#{singular_object_name}_id"] || params[:id])
    save_product_into_object_name_instance
  end

  def save_product_into_object_name_instance
    instance_variable_set("@#{singular_object_name}", @product)
  end
  # Get the object name to work off of. E.g. In ServicesController, this returns "services"
  def plural_object_name
    self.class.name.underscore.gsub(/_controller$/, "")
  end
  def singular_object_name
    plural_object_name.singularize
  end

end