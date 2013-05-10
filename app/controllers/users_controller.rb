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

  load_and_authorize_resource :except => [:password, :password_reset]

  layout 'two_column'

  def initialize
    @active_tab = 'admin_users'
    super
  end

  # GET /facilities/:facility_id/users
  def index
    @new_user = User.find_by_id(params[:user])
    @users = User.joins(:orders).
                  where(:orders => { :facility_id => current_facility.id }).
                  where('orders.ordered_at > ?', Time.zone.now - 1.year).
                  order(:last_name, :first_name).
                  select("DISTINCT users.*").
                  paginate(:page => params[:page])
  end

  def search
    @user = username_lookup(params[:username_lookup])
    render :layout => false
  end

  # GET /facilities/:facility_id/users/new
  def new
  end

  def new_external
    @user = User.new
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
    chars   = ("a".."z").to_a + ("1".."9").to_a + ("A".."Z").to_a
    newpass = Array.new(8, '').collect{chars[rand(chars.size)]}.join
    @user.password = newpass

    begin
      @user.save!
      redirect_to facility_users_path(:user => @user.id)
    rescue Exception => e
      @user.errors.add(:base, e) if @user.errors.empty?
      render :action => "new_external" and return
    end

    # send email
    Notifier.new_user(:user => @user, :password => newpass).deliver
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
    @user = User.find(params[:user_id])
    unless session_user.id == @user.id
      session[:acting_user_id] = params[:user_id]
      session[:acting_ref_url] = facility_users_path
    end
    redirect_to facility_path(current_facility)
  end

  # GET /facilities/:facility_id/users/:user_id/orders
  def orders
    @user = User.find(params[:user_id])
    # order details for this facility
    @order_details = @user.order_details.
      non_reservations.
      where("orders.facility_id = ? AND orders.ordered_at IS NOT NULL", current_facility.id).
      order('orders.ordered_at DESC').
      paginate(:page => params[:page])
  end

  # GET /facilities/:facility_id/users/:user_id/reservations
  def reservations
    @user = User.find(params[:user_id])
    # order details for this facility
    @order_details = @user.order_details.
      reservations.
      where("orders.facility_id = ? AND orders.ordered_at IS NOT NULL", current_facility.id).
      order('orders.ordered_at DESC').
      paginate(:page => params[:page])
  end

  # GET /facilities/:facility_id/users/:user_id/accounts
  def accounts
    @user = User.find(params[:user_id])
    # accounts for this facility
    @account_users = @user.account_users.active
  end

  # GET /facilities/:facility_id/users/:id
  def show
    @user = User.find(params[:id])
  end

  # GET /facilities/:facility_id/users/:user_id/instruments
  def instruments
    @user = User.find(params[:user_id])
    @approved_instruments = current_facility.instruments.select{ |inst| inst.is_approved_for?(@user) }
  end

  def email
  end

  private

  def username_lookup(username)
    return nil unless username.present?
    username_database_lookup(username) || service_username_lookup(username)
  end

  def username_database_lookup(username)
    User.where("LOWER(username) = ?", username.downcase).first
  end

  def save_user_success
    flash[:notice] = I18n.t('users.create.success')
    if session_user.manager_of?(current_facility)
      flash[:notice]=(flash[:notice] + "  You may wish to <a href=\"#{facility_facility_user_map_user_path(current_facility, @user)}\">add a facility role</a> for this user.").html_safe
    end
    Notifier.new_user(:user => @user, :password => nil).deliver
    redirect_to facility_users_path(:user => @user.id)
  end

end
