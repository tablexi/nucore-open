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
    @merge_orders=Order.where(:merge_with_order_id => @order.id, :created_by => current_user.id).all
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


  def send_receipt
    order=nil

    begin
      order=Order.find params[:id].to_i
      Notifier.order_receipt(:order => order, :user => order.user ).deliver
      flash[:notice]="Receipt sent successfully."
    rescue => e
      flash[:error]="There was a problem while sending the receipt: #{e.message}"
    end

    begin
      redirect_to :back
    rescue ActionController::RedirectBackError
      redirect_to order ? edit_facility_order_path(current_facility, order) : root_path
    end
  end


  def update
    product=Product.find(params[:product_add].to_i)
    order=original_order=Order.find(params[:id].to_i)
    quantity=params[:product_add_quantity].to_i

    if quantity <= 0
      flash[:notice]=I18n.t 'controllers.facility_orders.update.zero_quantity'
    else
      if merge?(product)
        order=Order.create!(
          :merge_with_order_id => original_order.id,
          :facility_id => original_order.facility_id,
          :account_id => original_order.account_id,
          :user_id => original_order.user_id,
          :created_by => current_user.id,
          :ordered_at => Time.zone.now
        )
      end

      begin
        details=order.add product, quantity

        details.each do |d|
          d.set_default_status!

          if order.to_be_merged? && ((d.product.is_a?(Instrument) && !d.valid_reservation?) || (d.product.is_a?(Service) && !d.valid_service_meta?))
            MergeNotification.create_for! current_user, d
          end
        end

        flash[:notice]=I18n.t 'controllers.facility_orders.update.success', :product => product.name
      rescue Exception => e
        Rails.logger.error "#{e.message}\n#{e.backtrace.join("\n")}"
        order.destroy if order != original_order
        flash[:error]=I18n.t 'controllers.facility_orders.update.error', :product => product.name
      end
    end

    redirect_to edit_facility_order_path(current_facility, original_order)
  end


  private

  def merge?(product)
    products=product.is_a?(Bundle) ? product.products : [ product ]

    products.each do |p|
      return true if p.is_a?(Instrument) || (p.is_a?(Service) && (p.active_survey? || p.active_template?))
    end

    false
  end
end
