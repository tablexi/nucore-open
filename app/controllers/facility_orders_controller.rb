class FacilityOrdersController < ApplicationController
  include TabCountHelper
  
  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility

  load_and_authorize_resource :class => Order

  helper_method :sort_column, :sort_direction
  
  include FacilityOrderStatusHelper


  def initialize
    @active_tab = 'admin_orders'
    super
  end


  # GET /facility/1/orders
  def index
    @order_details = new_or_in_process_orders.paginate(:page => params[:page])
  end


  # GET /facilities/:facility_id/orders/review
  def show_problems
    @order_details = problem_orders.paginate(:page => params[:page])
  end


  # GET /facilities/:facility_id/orders/disputed
  def disputed
    @order_details = disputed_orders.paginate(:page => params[:page])
  end


  # GET /facilities/example/orders/2/edit
  def edit
    @order=current_facility.orders.find params[:id]
    @order_details=@order.order_details.paginate(:page => params[:page])
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


  def update
    product=Product.find params[:product_add].to_i
    original_order=Order.find params[:id].to_i
    quantity=params[:product_add_quantity].to_i

    if quantity <= 0
      flash[:notice]=I18n.t 'controllers.facility_orders.add.zero_quantity'
    else
      @order=Order.create!(
        :merge_with_order_id => original_order.id,
        :facility_id => original_order.facility_id,
        :account_id => original_order.account_id,
        :user_id => original_order.user_id,
        :created_by => current_user.id,
        :ordered_at => Time.zone.now
      )

      begin
        @order.add product, quantity
        flash[:notice]=I18n.t 'controllers.facility_orders.add.success', :product => product.name
      rescue Exception => e
        Rails.logger.error "#{e.message}\n#{e.backtrace.join("\n")}"
        @order.destroy
        flash[:error]=I18n.t 'controllers.facility_orders.add.error', :product => product.name
      end
    end

    redirect_to edit_facility_order_path(current_facility, original_order)
  end
end
