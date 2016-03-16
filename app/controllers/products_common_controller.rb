class ProductsCommonController < ApplicationController
  customer_tab  :show
  admin_tab     :create, :destroy, :new, :edit, :index, :update, :manage
  before_filter :authenticate_user!, :except => [:show]
  before_filter :check_acting_as, :except => [:show]
  before_filter :init_current_facility
  before_filter :init_product, :except => [:index, :new, :create]
  before_filter :store_fullpath_in_session

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

  # GET /facilities/:facility_id/(services|items|bundles)/:(service|item|bundle)_id
  # TODO InstrumentsController#show has a lot in common; refactor/extract/consolidate
  def show
    @show_product = ShowProduct.new(self, @product, acting_user, session_user, acting_as?)
    @add_to_cart = @show_product.able_to_add_to_cart?
    @login_required = @show_product.login_required
    @error = @show_product.error

    if @show_product.redirect.present?
      flash[:notice] = @show_product.error if @show_product.error
      redirect_to @show_product.redirect
    else
      flash.now[:notice] = @show_product.error if @show_product.error
      @active_tab = "home"
      render layout: "application"
    end
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

  # The equivalent of calling current_facility.services or current_facility.items
  def current_facility_products
    return current_facility.send(:"#{plural_object_name}")
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
