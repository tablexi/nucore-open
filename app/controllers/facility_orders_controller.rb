# frozen_string_literal: true

class FacilityOrdersController < ApplicationController

  include NewInprocessController
  include SortableColumnController
  include ProblemOrderDetailsController
  include TabCountHelper

  admin_tab     :all
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_current_facility

  before_action :load_order, only: [:edit, :show, :update, :send_receipt]
  before_action :load_merge_orders, only: [:edit, :show]

  load_and_authorize_resource class: Order

  def initialize
    @active_tab = "admin_orders"
    super
  end

  # GET /facility/1/orders
  # Provided by NewInprocessController
  # def index
  # end

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
      PurchaseNotifier.order_receipt(order: @order, user: @order.user).deliver_later
      flash[:notice] = "Receipt sent successfully."
    rescue => e
      flash[:error] = "There was a problem while sending the receipt: #{e.message}"
    end

    redirect_fallback = @order ? facility_order_path(current_facility, @order) : root_path
    redirect_back(fallback_location: redirect_fallback)
  end

  # PUT/PATCH /facilities/:facility_id/orders/:id
  def update
    product = current_facility.products.find(params[:product_add])
    quantity = params.fetch(:product_add_quantity, 1).to_i
    params[:duration] = params[:product_add_duration]

    if quantity <= 0
      flash[:notice] = text("update.zero_quantity")
    else
      begin
        if order_appender.add!(product, quantity, params)
          flash[:error] = text("update.notices", product: product.name)
        else
          flash[:notice] = text("update.success", product: product.name)
        end
      rescue AASM::InvalidTransition
        flash[:error] = invalid_transition_message(product, params[:order_status_id])
      rescue ActiveRecord::RecordInvalid => e
        flash[:error] = e.record.errors.full_messages.to_sentence
      rescue => e
        Rails.logger.error "#{e.message}\n#{e.backtrace.join("\n")}"
        flash[:error] = text("update.error", product: product.name)
      end
    end

    redirect_to facility_order_path(current_facility, @order)
  end

  protected

  def show_problems_path
    show_problems_facility_orders_path
  end

  private

  def batch_updater
    @batch_updater ||= OrderDetailBatchUpdater.new(params[:order_detail_ids], current_facility, session_user, params)
  end

  def invalid_transition_message(product, order_status_id)
    text("update.invalid_status",
         product: product,
         status: OrderStatus.find(order_status_id))
  end

  def load_order
    @order = current_facility.orders.find params[:id]
  end

  def load_merge_orders
    @merge_orders = Order.where(merge_with_order_id: @order.id, created_by: current_user.id)
  end

  def order_appender
    @order_appender ||= OrderAppender.new(@order, current_user)
  end

  def new_or_in_process_orders
    # will never include instrument order details
    current_facility.order_details
                    .new_or_inprocess
                    .item_and_service_orders
  end

  def problem_order_details
    current_facility.problem_plain_order_details
  end

  def sort_lookup_hash
    {
      "order_number" => ["order_details.order_id", "order_details.id"],
      "date" => "orders.ordered_at",
      "product" => ["products.name", "order_details.state", "orders.ordered_at"],
      "assigned_to" => ["assigned_users.last_name", "assigned_users.first_name", "order_statuses.name", "orders.ordered_at"],
      "status" => ["order_statuses.name", "orders.ordered_at"],
    }
  end

end
