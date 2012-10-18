class PriceGroupsController < ApplicationController
  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility

  load_and_authorize_resource

  layout 'two_column'
  
  def initialize
    @active_tab = 'admin_facility'
    super
  end

  # GET /facilities/alias/price_groups
  def index
    @price_groups = current_facility.price_groups
  end

  # GET /facilities/alias/price_groups/1
  def show
    @price_group = current_facility.price_groups.find(params[:id])
    # redirect to accounts page
    redirect_to(accounts_facility_price_group_path(current_facility, @price_group)) and return
  end

  # GET /facilities/alias/price_groups/1/users
  def users
    @price_group = current_facility.price_groups.find(params[:id])
    raise ActiveRecord::RecordNotFound if @price_group.facility_id.nil?

    # find users associated with this price group
    @user_members = @price_group.user_price_group_members.paginate(:page => params[:page], :per_page => 10)
    @tab          = :users

    render(:action => 'show')
  end

  # GET /facilities/alias/price_groups/1/accounts
  def accounts
    @price_group      = current_facility.price_groups.find(params[:id])
    # find accounts associated with this price group
    @account_members  = @price_group.account_price_group_members.paginate(:page => params[:page], :per_page => 10)
    @tab              = :accounts

    render(:action => 'show')
  end

  # GET /price_groups/new
  def new
    @price_group = current_facility.price_groups.new
  end

  # GET /price_groups/1/edit
  def edit
    @price_group = current_facility.price_groups.find(params[:id])
    raise ActiveRecord::RecordNotFound if @price_group.nil?
  end

  # POST /price_groups
  def create
    @price_group = current_facility.price_groups.new(params[:price_group])

    respond_to do |format|
      if @price_group.save
        flash[:notice] = 'Price Group was successfully created.'
        format.html { redirect_to([current_facility, @price_group]) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /price_groups/1
  def update
    @price_group = current_facility.price_groups.find(params[:id])
    raise ActiveRecord::RecordNotFound if @price_group.nil?

    respond_to do |format|
      if @price_group.update_attributes(params[:price_group])
        flash[:notice] = 'Price Group was successfully updated.'
        format.html { redirect_to([current_facility, @price_group]) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /price_groups/1
  def destroy
    @price_group = current_facility.price_groups.find(params[:id])
    raise ActiveRecord::RecordNotFound if @price_group.nil? || @price_group.facility.nil?

    begin
      if @price_group.destroy
        flash[:notice] = 'Price Group was successfully deleted'
      else
        flash[:error] = 'The price group could not be deleted'
      end
    rescue ActiveRecord::ActiveRecordError => e
      puts e.to_yaml
      flash[:error] = e.message
    end
    respond_to do |format|
      format.html { redirect_to(facility_price_groups_url) }
    end
  end
end
