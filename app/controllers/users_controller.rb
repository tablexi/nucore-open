class UsersController < ApplicationController
  module Overridable
    def new_search
      if params[:username]
        @user = User.where("LOWER(username) = ?", params[:username].downcase).first
        flash[:notice] = "The user has been added successfully."
        if session_user.manager_of?(current_facility)
          flash[:notice]=(flash[:notice] + "  You may wish to <a href=\"#{facility_facility_user_map_user_url(current_facility, @user)}\">add a facility role</a> for this user.").html_safe
        end
        # send email
        Notifier.new_user(:user => @user, :password => nil).deliver
        redirect_to facility_users_url(current_facility)
      end
    end

    # POST /facilities/:facility_id/users/netid_search
    def username_search
      @user = User.find(:first, :conditions => ["LOWER(username) = ?", params[:username_lookup].downcase])
      render :layout => false
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

  # GET /facilities/:facility_id/facility_users/new
  def new
    @user = User.new
  end

  # POST /facilities/:facility_id/facility_users
  def create
    @user   = User.new(params[:user])
    chars   = ("a".."z").to_a + ("1".."9").to_a + ("A".."Z").to_a
    newpass = Array.new(8, '').collect{chars[rand(chars.size)]}.join
    @user.password = newpass

    begin
      @user.save!
      redirect_to facility_users_url(:user => @user.id)
    rescue Exception => e
      @user.errors.add(:base, e) if @user.errors.empty?
      render :action => "new" and return
    end

    # send email
    Notifier.new_user(:user => @user, :password => newpass).deliver
  end

  # GET /facilities/:facility_id/users/:user_id/switch_to
  def switch_to
    @user = User.find(params[:user_id])
    unless session_user.id == @user.id
      session[:acting_user_id] = params[:user_id]
      session[:acting_ref_url] = facility_users_url
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
  
end
