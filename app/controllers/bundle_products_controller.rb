class BundleProductsController < ApplicationController
  customer_tab  :show
  admin_tab     :create, :destroy, :new, :edit, :index, :update, :manage
  before_filter :authenticate_user!, :except => :show
  before_filter :check_acting_as
  before_filter :init_current_facility
  before_filter :init_bundle
  before_filter :init_bundle_product, :except => [:new, :create, :index]

  load_and_authorize_resource :except => :show

  layout 'two_column'

  def initialize
    @active_tab = 'admin_products'
    super
  end

  # GET /facilities/:facility_id/bundles/:bundle_id/bundle_products
  def index
    @bundle_products = @bundle.bundle_products
    @bundle_products.sort!
  end

  # POST /facilities/:facility_id/bundles/:bundle_id/bundle_products
  def create
    @bundle_product = @bundle.bundle_products.new(params[:bundle_product])

    if @bundle_product.save
      flash[:notice] = 'The product was successfully added to the bundle.'
      redirect_to facility_bundle_bundle_products_path(current_facility, @bundle)
    else
      render :action => "new"
    end
  end

  # GET /facilities/:facility_id/bundles/:bundle_id/bundle_products/new
  def new
    @bundle_product = @bundle.bundle_products.new(:quantity => 1)
  end

  # GET /facilities/:facility_id/bundles/:bundle_id/bundle_products/:id/edit
  def edit
  end

  # PUT /facilities/:facility_id/bundles/:bundle_id/bundle_products/:id
  def update
    if @bundle_product.update_attributes(params[:bundle_product])
      flash[:notice] = 'The bundle product was successfully updated.'
      redirect_to facility_bundle_bundle_products_path(current_facility, @bundle)
    else
      render :action => "edit"
    end
  end
  
  # DELETE /facilities/:facility_id/bundles/:bundle_id/bundle_products/:id
  def destroy
    if @bundle_product.destroy
      flash[:notice] = 'The product has been removed from the bundle successfully.'
    else
      flash[:error] = 'An error occurred while removing the product from the bundle.'
    end
    redirect_to facility_bundle_bundle_products_path(current_facility, @bundle)
  end
  
  def init_bundle
    @bundle = current_facility.bundles.find_by_url_name!(params[:bundle_id])
  end
  
  def init_bundle_product
    @bundle_product = @bundle.bundle_products.find(params[:id])
  end
end