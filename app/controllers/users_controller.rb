class UsersController < ApplicationController

  module Overridable

    # Should be overridden by custom lookups (e.g. LDAP)
    def service_username_lookup(_username)
      nil
    end

  end

  include Overridable
  include TextHelpers::Translation

  customer_tab :password
  admin_tab     :all
  before_action :init_current_facility, except: [:password, :password_reset]
  before_action :authenticate_user!, except: [:password_reset]
  before_action :check_acting_as

  load_and_authorize_resource except: [:password, :password_reset, :edit, :update], id_param: :user_id
  load_and_authorize_resource only: [:edit, :update], id_param: :id

  layout "two_column"

  def initialize
    @active_tab = "admin_users"
    super
  end

  # GET /facilities/:facility_id/users
  def index
    @new_user = User.find_by(id: params[:user])
    @users =
      User
      .with_recent_orders(current_facility)
      .order(:last_name, :first_name)
      .paginate(page: params[:page])
  end

  def search
    @user = username_lookup(params[:username_lookup])
    render layout: false
  end

  # GET /facilities/:facility_id/users/new
  def new
  end

  def new_external
    @user = User.new(email: params[:email], username: params[:email])
  end

  # POST /facilities/:facility_id/users
  def create
    if params[:user]
      create_external
    elsif params[:username]
      create_internal
    else
      redirect_to new_facility_user_path
    end
  end

  def create_external
    @user = User.new(params[:user])
    @user.password = generate_new_password

    if @user.save
      LogEvent.log(@user, :create, current_user)
      @user.create_default_price_group!
      save_user_success
    else
      render(action: "new_external") && return
    end
  end

  def create_internal
    @user = username_lookup(params[:username])
    if @user.nil?
      flash[:error] = text("users.search.netid_not_found")
      redirect_to facility_users_path
    elsif @user.persisted?
      flash[:error] = text("users.search.user_already_exists", username: @user.username)
      redirect_to facility_users_path
    elsif @user.save
      LogEvent.log(@user, :create, current_user)
      @user.create_default_price_group!
      save_user_success
    else
      flash[:error] = text("create.error", message: @user.errors.full_messages.to_sentence)
      redirect_to facility_users_path
    end
  end

  # GET /facilities/:facility_id/users/:user_id/switch_to
  def switch_to
    unless session_user.id == @user.id
      session[:acting_user_id] = @user.id
      session[:acting_ref_url] = facility_users_path
    end
    redirect_to facility_path(current_facility)
  end

  # GET /facilities/:facility_id/users/:user_id/orders
  def orders
    # order details for this facility
    @order_details = @user.order_details
                          .item_and_service_orders
                          .for_facility(current_facility)
                          .purchased
                          .order("orders.ordered_at DESC")
                          .paginate(page: params[:page])
  end

  # GET /facilities/:facility_id/users/:user_id/accounts
  def accounts
    # accounts for this facility
    @accounts = @user.accounts.for_facility(current_facility)
  end

  # GET /facilities/:facility_id/users/:id
  def show
    @user = User.find(params[:id])
  end

  # GET /facilities/:facility_id/users/:user_id/access_list
  def access_list
    @facility = current_facility
    @products_by_type = Product.for_facility(@facility).requiring_approval_by_type
    @training_requested_product_ids = @user.training_requests.pluck(:product_id)
  end

  def training_requested_for?(product)
    @training_requested_product_ids.include? product.id
  end
  helper_method :training_requested_for?

  # POST /facilities/:facility_id/users/:user_id/access_list/approvals
  def access_list_approvals
    update_access_list_approvals
    redirect_to facility_user_access_list_path(current_facility, @user)
  end

  def email
  end

  # GET /facilities/:facility_id/users/:id/edit
  def edit
    @user = User.find(params[:id])
  end

  # PUT /facilities/:facility_id/users/:id
  def update
    @user = User.find(params[:id])
    if @user.update_attributes(edit_user_params) && @user.update_price_group(price_group_params)
      flash[:notice] = text("update.success")
      redirect_to facility_user_path(current_facility, @user)
    else
      flash[:error] = text("update.error", message: @user.errors.full_messages.to_sentence)
      render action: "edit"
    end
  end

  private

  def edit_user_params
    if @user.admin_editable?
      params.require(:user).permit(:email, :first_name, :last_name, :username)
    else
      ActionController::Parameters.new
    end
  end

  def price_group_params
    current_user.administrator? ? params.require(:user).permit(:internal) : ActionController::Parameters.new
  end

  def update_access_list_approvals
    if update_approvals.grants_changed?
      flash[:notice] = I18n.t "controllers.users.access_list.approval_update.notice",
                              granted: update_approvals.granted, revoked: update_approvals.revoked
    end
    if update_approvals.access_groups_changed?
      add_flash(:notice,
                I18n.t("controllers.users.access_list.scheduling_group_update.notice",
                       update_count: update_approvals.access_groups_changed))
    end
  end

  def update_approvals
    @update_approvals ||= ProductApprover.new(
      Product.for_facility(current_facility).requiring_approval,
      @user,
      session_user,
    ).update_approvals(approved_products_from_params, params[:product_access_group])
  end

  def approved_products_from_params
    if params[:approved_products].present?
      Product.find(params[:approved_products])
    else
      []
    end
  end

  def username_lookup(username)
    return nil unless username.present?
    username_database_lookup(username.strip) || service_username_lookup(username.strip)
  end

  def username_database_lookup(username)
    User.find_by("LOWER(username) = ?", username.downcase)
  end

  def generate_new_password
    chars = ("a".."z").to_a + ("1".."9").to_a + ("A".."Z").to_a
    chars.sample(8).join
  end

  def save_user_success
    flash[:notice] = text("create.success")
    if session_user.manager_of?(current_facility)
      add_role = html("create.add_role", link: facility_facility_user_map_user_path(current_facility, @user), inline: true)
      flash[:notice].safe_concat(add_role)
    end
    Notifier.new_user(user: @user, password: @user.password).deliver_later
    redirect_to facility_users_path(user: @user.id)
  end

  def add_flash(key, message)
    if flash[key].present?
      flash[key] += " #{message}"
    else
      flash[key] = message
    end
  end

end
