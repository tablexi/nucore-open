class OrderStatusesController < ApplicationController
  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility

  load_and_authorize_resource
  # Disallow editing root statuses
  before_filter :ensure_editable, :only => [:edit, :update, :destroy]

  layout 'two_column'

  def initialize
    @active_tab = 'admin_facility'
    super
  end

  # GET /order_statuses
  def index
    @order_statuses       = current_facility.order_statuses
    @root_order_statuses  = OrderStatus.roots #.sort {|a,b| a.lft <=> b.lft }
  end

  # GET /order_statuses/new
  def new
    @order_status = current_facility.order_statuses.new
  end

  # GET /facilities/:facility_id/order_statuses/:id/edit
  def edit
    @order_status = current_facility.order_statuses.find(params[:id])
  end

  # POST /order_statuses
  def create
    @order_status = current_facility.order_statuses.new(params[:order_status])

    if @order_status.save
      flash[:notice] = 'The Order Status was successfully created.'
      redirect_to facility_order_statuses_url
    else
      render :action => "new"
    end
  end

  # PUT /facilities/:facility_id/order_statuses/:id
  def update
    @order_status = current_facility.order_statuses.find(params[:id])

    if @order_status.update_attributes(params[:order_status])
      flash[:notice] = 'The Order Status was successfully updated.'
      redirect_to facility_order_statuses_path
    else
      render :action => "edit"
    end
  end

  # DELETE /facilities/:facility_id/order_statuses/:id
  def destroy
    @order_status = current_facility.order_statuses.find(params[:id])
    parent_status = @order_status.root
    @order_status.transaction do
      begin
        # used instead of update_all so vestal_versions can do its thing; annoying, I know
        @order_status.order_details.each{ |os| os.update_attribute(:order_status, parent_status) }
        @order_status.destroy
        flash[:notice] = 'The order status was successfully removed.'
      rescue => e
        flash[:error] = 'An error was encountered while removing the order status.'
        raise ActiveRecord::Rollback
      end
    end
    redirect_to facility_order_statuses_url
  end

  private

  def ensure_editable
    raise ActiveRecord::RecordNotFound unless @order_status.editable?
  end
end
