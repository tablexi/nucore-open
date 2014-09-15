class UsersController < ApplicationController
  module Overridable
    # Should be overridden by custom lookups (e.g. LDAP)
    def service_username_lookup(username)
      nil
    end
  end

  include Overridable

  customer_tab :password
  admin_tab     :all
  before_filter :init_current_facility, :except => [:password, :password_reset]
  before_filter :authenticate_user!, :except => [:password_reset]
  before_filter :check_acting_as
  before_filter :load_user_from_user_id_param, only: [:access_list, :access_list_approvals, :accounts, :orders, :reservations, :switch_to]

  load_and_authorize_resource :except => [:password, :password_reset]

  layout 'two_column'

  def initialize
    @active_tab = 'admin_users'
    super
  end

  # GET /facilities/:facility_id/users
  def index
    @new_user = User.find_by_id(params[:user])

    @users = User.with_recent_orders(current_facility)
                  .order(:last_name, :first_name)
                  .paginate(:page => params[:page])
  end

  def search
    @user = username_lookup(params[:username_lookup])
    render :layout => false
  end

  # GET /facilities/:facility_id/users/new
  def new
  end

  def new_external
    @user = User.new(:email => params[:email], :username => params[:email])
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
    @user   = User.new(params[:user])
    @user.password = generate_new_password

    if @user.save
      # send email
      Notifier.new_user(:user => @user, :password => @user.password).deliver
      redirect_to facility_users_path(:user => @user.id)
    else
      render :action => "new_external" and return
    end
  end

  def create_internal
    @user = username_lookup(params[:username])
    if @user.nil?
      flash[:error] = I18n.t('users.search.notice1')
      redirect_to facility_users_path
    elsif @user.persisted?
      flash[:error] = I18n.t('users.search.user_already_exists', :username => @user.username)
      redirect_to facility_users_path
    elsif @user.save
      save_user_success
    else
      flash[:error] = I18n.t('users.create.error')
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
    @order_details = @user.order_details.
      non_reservations.
      where("orders.facility_id = ? AND orders.ordered_at IS NOT NULL", current_facility.id).
      order('orders.ordered_at DESC').
      paginate(:page => params[:page])
  end

  # GET /facilities/:facility_id/users/:user_id/reservations
  def reservations
    # order details for this facility
    @order_details = @user.order_details.
      reservations.
      where("orders.facility_id = ? AND orders.ordered_at IS NOT NULL", current_facility.id).
      order('orders.ordered_at DESC').
      paginate(:page => params[:page])
  end

  # GET /facilities/:facility_id/users/:user_id/accounts
  def accounts
    # accounts for this facility
    @account_users = @user.account_users.active
  end

  # GET /facilities/:facility_id/users/:id
  def show
    @user = User.find(params[:id])
  end

  # GET /facilities/:facility_id/users/:user_id/access_list
  def access_list
    @facility = current_facility
    @products_by_type = @facility.products_requiring_approval_by_type
  end

  # POST /facilities/:facility_id/users/:user_id/access_list/approvals
  def access_list_approvals
    update_access_list_approvals
    redirect_to facility_user_access_list_path(current_facility, @user)
  end

  def email
  end

  private

  def update_access_list_approvals
    if update_approvals.grants_changed?
      flash[:notice] = I18n.t 'controllers.users.access_list.approval_update.notice',
        granted: update_approvals.granted, revoked: update_approvals.revoked
    end
    if update_approvals.access_groups_changed?
      add_flash(:notice,
        I18n.t('controllers.users.access_list.scheduling_group_update.notice',
          update_count: update_approvals.access_groups_changed))
    end
  end

  def update_approvals
    @update_approvals ||= ProductApprover.new(
      current_facility.products_requiring_approval,
      @user,
      session_user
    ).update_approvals(approved_products_from_params, params[:product_access_group])
  end

  def approved_products_from_params
    if params[:approved_products].present?
      Product.find(params[:approved_products])
    else
      []
    end
  end

  def load_user_from_user_id_param
    @user = User.find(params[:user_id])
  end

  def username_lookup(username)
    return nil unless username.present?
    username_database_lookup(username) || service_username_lookup(username)
  end

  def username_database_lookup(username)
    User.where("LOWER(username) = ?", username.downcase).first
  end

  def generate_new_password
    chars   = ("a".."z").to_a + ("1".."9").to_a + ("A".."Z").to_a
    chars.sample(8).join
  end

  def save_user_success
    flash[:notice] = I18n.t('users.create.success')
    if session_user.manager_of?(current_facility)
      flash[:notice]=(flash[:notice] + "  You may wish to <a href=\"#{facility_facility_user_map_user_path(current_facility, @user)}\">add a facility role</a> for this user.").html_safe
    end
    Notifier.new_user(:user => @user, :password => nil).deliver
    redirect_to facility_users_path(:user => @user.id)
  end

  def add_flash(key, message)
    if flash[key].present?
      flash[key] += " #{message}"
    else
      flash[key] = message
    end
  end

end
