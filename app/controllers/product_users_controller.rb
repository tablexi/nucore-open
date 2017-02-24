class ProductUsersController < ApplicationController

  admin_tab :index, :new
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_current_facility
  before_action :init_product

  load_and_authorize_resource

  layout "two_column"

  include SearchHelper

  def initialize
    @active_tab = "admin_products"
    super
  end

  # GET /facilities/:facility_id/bundles/bundle_id/users
  # GET /facilities/:facility_id/instruments/instrument_id/users
  # GET /facilities/:facility_id/items/item_id/users
  # GET /facilities/:facility_id/services/service_id/users
  def index
    if @product.requires_approval?
      @product_users = @product
        .product_users
        .includes(:user)
        .order("users.last_name ASC", "users.first_name ASC")
        .paginate(page: params[:page])
    else
      @product_users = nil
      flash.now[:notice] = text("index.not_required", model: downcase_product_type)
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
      flash[:notice] = text("new.success", model: downcase_product_type)
    else
      flash[:error] = product_user.errors.full_messages.to_sentence
    end
    redirect_to action: :index
  end

  # DELETE /facilities/:facility_id/bundles/bundle_id/users/:id
  # DELETE /facilities/:facility_id/instruments/instrument_id/users/:id
  # DELETE /facilities/:facility_id/items/item_id/users/:id
  # DELETE /facilities/:facility_id/services/service_id/users/:id
  def destroy
    product_user = ProductUser.find_by(product_id: @product.id, user_id: params[:id])
    product_user.destroy

    if product_user.destroyed?
      flash[:notice] = text("destroy.success", model: downcase_product_type)
    else
      flash[:error]  = text("destroy.failure", model: downcase_product_type)
    end

    redirect_to action: :index
  end

  # /facilities/:facility_id/services/:service_id/users/user_search_results
  def user_search_results
    @limit = 25

    term = generate_multipart_like_search_term(params[:search_term])
    if params[:search_term].length > 0
      @users = User
        .where("LOWER(first_name) LIKE :term OR LOWER(last_name) LIKE :term OR LOWER(username) LIKE :term OR LOWER(CONCAT(first_name, last_name)) LIKE :term", term: term)
        .order(:last_name, :first_name)
        .limit(@limit)
      @count = @users.count
    end

    render layout: false
  end

  # PUT /facilities/:facility_id/instruments/:instrument_id/update_restrictions
  def update_restrictions
    product_param_name = @product.class.name.underscore
    unless params[product_param_name]
      redirect_to action: :index
      return
    end
    params[product_param_name][:product_users].each do |key, value|
      product_user = @product.product_users.find(key)
      product_user.update_attributes(value)
    end

    flash[:notice] = text("update_restrictions.success")
    redirect_to action: :index
  end

  private

  def downcase_product_type
    @product.class.model_name.human.downcase
  end

  def init_product
    @product = current_facility.products
                               .find_by!(url_name: product_id)
    @product_user = @product.product_users.build # for CanCan auth
  end

  def product_id
    key = params.except(:facility_id).keys.find { |k| k.end_with?("_id") }
    params[key]
  end

end
