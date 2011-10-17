class FacilityOrdersController < ApplicationController
  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility

  load_and_authorize_resource :class => Order

  helper_method :sort_column, :sort_direction

  def initialize
    @active_tab = 'admin_orders'
    super
  end

  # GET /facility/1/orders
  def index
    # will never include instrument order details
    facility_ods = current_facility.order_details.non_reservations

    @order_details = case sort_column
      when 'order_number'
        facility_ods.find(:all,
                          :joins => 'INNER JOIN orders ON orders.id = order_details.order_id',
                          :conditions => ['(order_details.state = ? OR order_details.state = ?) AND orders.state = ?', 'new', 'inprocess', 'purchased'],
                          :order => "CONCAT(CONCAT(order_details.order_id, '-'), order_details.id) #{sort_direction}").paginate(:page => params[:page])
      when 'date'
        facility_ods.find(:all,
                          :joins => 'INNER JOIN orders ON orders.id = order_details.order_id',
                          :conditions => ['(order_details.state = ? OR order_details.state = ?) AND orders.state = ?', 'new', 'inprocess', 'purchased'],
                          :order => "orders.ordered_at #{sort_direction}").paginate(:page => params[:page])
      when 'product'
        facility_ods.find(:all,
                          :joins => 'INNER JOIN orders ON orders.id = order_details.order_id',
                          :conditions => ['(order_details.state = ? OR order_details.state = ?) AND orders.state = ?', 'new', 'inprocess', 'purchased'],
                          :order => "products.name #{sort_direction}, order_details.state, orders.ordered_at").paginate(:page => params[:page])
      when 'assigned_to'
        facility_ods.find(:all,
                          :joins => ['INNER JOIN order_statuses ON order_details.order_status_id = order_statuses.id ',
                                     'INNER JOIN orders ON orders.id = order_details.order_id ',
                                     "LEFT JOIN #{User.table_name} ON order_details.assigned_user_id = #{User.table_name}.id "],
                          :conditions => ['(order_details.state = ? OR order_details.state = ?) AND orders.state = ?', 'new', 'inprocess', 'purchased'],
                          :order => "#{User.table_name}.last_name #{sort_direction}, #{User.table_name}.first_name #{sort_direction}, order_statuses.name, orders.ordered_at"
        ).paginate(:page => params[:page])
      when 'status'
        facility_ods.find(:all,
                          :joins => ['INNER JOIN orders ON orders.id = order_details.order_id ',
                                     'INNER JOIN order_statuses ON order_details.order_status_id = order_statuses.id '],
                          :conditions => ['(order_details.state = ? OR order_details.state = ?) AND orders.state = ?', 'new', 'inprocess', 'purchased'],
                          :order => "order_statuses.name #{sort_direction}, orders.ordered_at").paginate(:page => params[:page])
      else
        facility_ods.new_or_inprocess.paginate(:page => params[:page])
    end
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
    @order_details = current_facility.order_details.
      non_reservations.
      reject{|od| !od.problem_order?}.
      paginate(:page => params[:page])
  end

  # GET /facilities/:facility_id/orders/disputed
  def disputed
    @details = current_facility.order_details.
      non_reservations.
      in_dispute.
      paginate(:page => params[:page])
  end
  
  private
  def sort_column
    params[:sort] || 'order_number'
  end
  
  def sort_direction
    (params[:dir] || '') == 'desc' ? 'desc' : 'asc'
  end
end
