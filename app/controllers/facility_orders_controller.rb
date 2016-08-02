class FacilityOrdersController < ApplicationController

  include ProblemOrderDetailsController
  include TabCountHelper

  admin_tab     :all
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_current_facility

  load_and_authorize_resource class: Order

  before_action :load_order, only: [:edit, :show, :update, :send_receipt]
  before_action :load_merge_orders, only: [:edit, :show]

  include FacilityOrderStatusHelper

  def initialize
    @active_tab = "admin_orders"
    super
  end

  # GET /facility/1/orders
  def index
    @order_details = new_or_in_process_orders.paginate(page: params[:page])
  end

  # GET /facilities/:facility_id/orders/disputed
  def disputed
    @order_details = disputed_orders.paginate(page: params[:page])
  end

  def show
    @order_details = @order.order_details.ordered_by_parents
    @order_details = @order_details.includes(:reservation, :order_status, :product, :order)
  end

  ## POST /facilities/:facility_id/orders/batch_update
  def batch_update
    redirect_to facility_orders_path

    msg_hash = batch_updater.update!

    # add flash messages if necessary
    flash.merge!(msg_hash) if msg_hash
  end

  def send_receipt
    begin
      Notifier.delay.order_receipt(order: @order, user: @order.user)
      flash[:notice] = "Receipt sent successfully."
    rescue => e
      flash[:error] = "There was a problem while sending the receipt: #{e.message}"
    end

    begin
      redirect_to :back
    rescue ActionController::RedirectBackError
      redirect_to @order ? facility_order_path(current_facility, @order) : root_path
    end
  end

  def update
    product = Product.find(params[:product_add].to_i)
    original_order = @order
    quantity = params[:product_add_quantity].to_i

    if quantity <= 0
      flash[:notice] = I18n.t "controllers.facility_orders.update.zero_quantity"
    else
      add_to_order(product, quantity, original_order)
    end

    redirect_to facility_order_path(current_facility, original_order)
  end

  protected

  def show_problems_path
    show_problems_facility_orders_path
  end

  def problem_order_details
    current_facility.problem_non_reservation_order_details
  end

  private

  def batch_updater
    @batch_updater ||= OrderDetailBatchUpdater.new(params[:order_detail_ids], current_facility, session_user, params)
  end

  def merge?(product)
    products = product.is_a?(Bundle) ? product.products : [product]

    products.any? do |p|
      p.is_a?(Instrument) || (p.is_a?(Service) && (p.active_survey? || p.active_template?))
    end
  end

  def add_to_order(product, quantity, original_order)
    @order = build_merge_order if merge?(product)

    begin
      details = @order.add product, quantity
      notifications = false
      details.each do |d|
        d.set_default_status!
        if @order.to_be_merged? && !d.valid_for_purchase?
          notifications = true
          MergeNotification.create_for! current_user, d
        end
      end

      if notifications
        flash[:error] = I18n.t "controllers.facility_orders.update.notices", product: product.name
      else
        flash[:notice] = I18n.t "controllers.facility_orders.update.success", product: product.name
      end
    rescue => e
      Rails.logger.error "#{e.message}\n#{e.backtrace.join("\n")}"
      @order.destroy if @order != original_order
      flash[:error] = I18n.t "controllers.facility_orders.update.error", product: product.name
    end
  end

  def build_merge_order
    Order.create!(
      merge_with_order_id: @order.id,
      facility_id: @order.facility_id,
      account_id: @order.account_id,
      user_id: @order.user_id,
      created_by: current_user.id,
    )
  end

  def load_order
    @order = current_facility.orders.find params[:id]
  end

  def load_merge_orders
    @merge_orders = Order.where(merge_with_order_id: @order.id, created_by: current_user.id)
  end

end
