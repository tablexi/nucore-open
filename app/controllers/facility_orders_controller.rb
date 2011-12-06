class FacilityOrdersController < ApplicationController
  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility

  load_and_authorize_resource :class => Order

  helper_method :sort_column, :sort_direction
  
  include FacilityOrderStatusHelper
  helper_method :new_or_in_process_orders, :problem_orders, :disputed_orders
  
  def initialize
    @active_tab = 'admin_orders'
    super
  end

  # GET /facility/1/orders
  def index
    @order_details = new_or_in_process_orders.paginate(:page => params[:page])
  end

  # GET /facility/1/orders/2
  def show
    # @facility = Facility.find_by_url_name!(params[:facility_id])
    @order = current_facility.orders.find(params[:id])
    # raise ActiveRecord::RecordNotFound if @order.nil?
  end

  ## POST /facilities/:facility_id/orders/batch_update
  def batch_update
    redirect_to facility_orders_path

    msg_hash = OrderDetail.batch_update(params[:order_detail_ids], current_facility, session_user, params)
    
    # add flash messages if necessary
    if msg_hash
      flash.merge!(msg_hash)
    end
  end

  # GET /facilities/:facility_id/orders/review
  def show_problems
    @details = problem_orders.paginate(:page => params[:page])
  end

  # GET /facilities/:facility_id/orders/disputed
  def disputed
    @order_details = disputed_orders.paginate(:page => params[:page])
    
  end
  
  
  
end
