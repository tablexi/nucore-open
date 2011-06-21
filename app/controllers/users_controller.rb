class UsersController < ApplicationController
  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility

  load_and_authorize_resource

  layout 'two_column'

  def initialize 
    @active_tab = 'admin_users'
    super
  end

  # GET /facilities/:facility_id/users
  def index
    @users = current_facility.orders.find(:all, :conditions => ['ordered_at > ?', Time.zone.now - 1.year]).collect{|o| o.user}.uniq
    @users.delete nil # on a dev db with screwy data nil can get ya
    @users = @users.sort {|x,y| [x.last_name, x.first_name].join(' ') <=> [y.last_name, y.first_name].join(' ') }.paginate(:page => params[:page])
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
      flash[:notice] = 'The user was successfully created.'
      redirect_to facility_users_url
    rescue Exception => e
      @user.errors.add_to_base(e) if @user.errors.empty?
      render :action => "new" and return
    end

    # send email
    Notifier.deliver_new_user(:user => @user, :password => newpass)
  end

  def new_search
    if params[:username]
      @user = User.find(:first, :conditions => ["LOWER(username) = ?", params[:username].downcase])
      flash[:notice] = "The user has been added successfully."
      if session_user.manager_of?(current_facility)
        flash[:notice] += "  You may wish to <a href=\"#{facility_facility_user_map_user_url(current_facility, @user)}\">add a facility role</a> for this user."
      end
      # send email
      Notifier.deliver_new_user(:user => @user, :password => nil)
      redirect_to facility_users_url(current_facility)
    end
  end

  # POST /facilities/:facility_id/users/netid_search
  def username_search
    @user = User.find(:first, :conditions => ["LOWER(username) = ?", params[:username_lookup].downcase])
    render :layout => false
  end

  # GET /facilities/:facility_id/users/:user_id/switch_to
  def switch_to
    @user = User.find(params[:user_id])
    unless session_user.id == @user.id
      session[:acting_user_id] = params[:user_id]
      session[:acting_ref_url] = facility_users_url
    end
    redirect_to facilities_path
  end

  # GET /facilities/:facility_id/users/:user_id/orders
  def orders
    @user = User.find(params[:user_id])
    # order details for this facility
    @order_details = @user.order_details.find(:all, :conditions => "orders.facility_id = #{@current_facility.id} AND orders.ordered_at IS NOT NULL", :order => 'orders.ordered_at DESC').paginate(:page => params[:page])
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