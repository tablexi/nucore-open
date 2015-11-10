class ProductUsersController < ApplicationController
  admin_tab :index, :new
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility
  before_filter :init_product

  load_and_authorize_resource

  layout 'two_column'

  include SearchHelper

  def initialize
    @active_tab = 'admin_products'
    super
  end

  # GET /facilities/:facility_id/bundles/bundle_id/users
  # GET /facilities/:facility_id/instruments/instrument_id/users
  # GET /facilities/:facility_id/items/item_id/users
  # GET /facilities/:facility_id/services/service_id/users
  def index
    if @product.requires_approval?
      @product_users = @product.product_users.includes(:user).order(:user => [:last_name, :first_name])
      @product_users = @product_users.paginate(:page => params[:page])
    else
      @product_users = nil
      flash.now[:notice] = "This #{@product.class.name.downcase} does not require user authorization"
    end
  end

  # GET /facilities/:facility_id/bundles/bundle_id/users/new
  # GET /facilities/:facility_id/instruments/instrument_id/users/new
  # GET /facilities/:facility_id/items/item_id/users/new
  # GET /facilities/:facility_id/services/service_id/users/new
  def new
    return unless params[:user]
    product_user = ProductUserCreator.create(user: User.find(params[:user]), product: @product, approver: session_user)
    if product_user.persisted?
      flash[:notice] = "The user has been successfully authorized for this #{@product.class.name.downcase}"
    else
      flash[:error] = product_user.errors.full_messages.to_sentence
    end
    redirect_to(send("facility_#{@product.class.name.downcase}_users_url", current_facility, @product))
  end

  # DELETE /facilities/:facility_id/bundles/bundle_id/users/:id
  # DELETE /facilities/:facility_id/instruments/instrument_id/users/:id
  # DELETE /facilities/:facility_id/items/item_id/users/:id
  # DELETE /facilities/:facility_id/services/service_id/users/:id
  def destroy
    product_user = ProductUser.find(:first, :conditions => { :product_id => @product.id, :user_id => params[:id] })
    product_user.destroy

    if product_user.destroyed?
      flash[:notice] = "The user has been successfully removed from this #{@product.class.name.downcase}"
    else
      flash[:error]  = "An error was encountered while attempting to remove the user from this #{@product.class.name.downcase}"
    end

    redirect_to(self.send("facility_#{@product.class.name.downcase}_users_url", current_facility, @product))
  end

  # /facilities/:facility_id/services/:service_id/users/user_search_results
  def user_search_results
    @limit = 25

    term = generate_multipart_like_search_term(params[:search_term])
    if params[:search_term].length > 0
      conditions = ["LOWER(first_name) LIKE ? OR LOWER(last_name) LIKE ? OR LOWER(username) LIKE ? OR LOWER(CONCAT(first_name, last_name)) LIKE ?", term, term, term, term]
      @users = User.find(:all, :conditions => conditions, :order => "last_name, first_name", :limit => @limit)
      @count = @users.length
    end

    render :layout => false
  end

  # PUT /facilities/:facility_id/instruments/:instrument_id/update_restrictions
  def update_restrictions
    product_param_name = @product.class.name.underscore.downcase
    unless params[product_param_name]
      redirect_to self.send("facility_#{product_param_name}_users_url", current_facility, @product)
      return
    end
    params[product_param_name][:product_users].each do |key, value|
      product_user = @product.product_users.find(key)
      product_user.update_attributes(value)
    end

    flash[:notice] = t("product_users.update_restrictions.notice")
    redirect_to self.send("facility_#{product_param_name}_users_url", current_facility, @product)
  end

  def init_product
    @product = current_facility.products.find_by_url_name!(params[:instrument_id] || params[:service_id] || params[:item_id])
    @product_user=ProductUser.first # for CanCan auth
  end
end
