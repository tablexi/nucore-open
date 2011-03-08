class ProductUsersController < ApplicationController
  admin_tab :index, :new
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility
  before_filter :init_product

  load_and_authorize_resource

  layout 'two_column'

  def initialize
    @active_tab = 'admin_products'
    super
  end

  # GET /users
  def index
    if @product.requires_approval?
      @users = @product.product_users
      @users = @product.product_users.map { |pu| pu.user }
      @users = @users.sort_by { |u| [ u.last_name, u.first_name ] }.paginate(:page => params[:page])
    else
      @users = nil
      flash.now[:notice] = "This #{@product.class.name.downcase} does not require user authorization"
    end
  end

  # GET /users/new
  def new
    if params[:user]
      user = User.find(params[:user])
      pu   = ProductUser.new(:product => @product, :user => user, :approved_by => session_user.id, :approved_at => Time.zone.now)
      if pu.save
        flash[:notice] = "The user has been successfully authorized for this #{@product.class.name.downcase}"
      else
        flash[:error] = pu.errors.full_messages
      end
      redirect_to(self.send("facility_#{@product.class.name.downcase}_users_url", current_facility, @product))
    end
  end

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

  def init_product
    @product = current_facility.products.find_by_url_name!(params[:instrument_id] || params[:service_id] || params[:item_id])
  end
end
