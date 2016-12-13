class OrderDetailsController < ApplicationController

  customer_tab  :all

  before_action :authenticate_user!
  before_action :check_acting_as, except: [:order_file, :upload_order_file, :remove_order_file]
  before_action :init_order_detail
  before_action :set_active_tab
  before_action :prevent_edit_based_on_state, only: [:edit, :update]
  authorize_resource

  # GET /orders/:order_id/order_details/:id
  def show
    @order_detail.send(:extend, PriceDisplayment)
  end

  # GET /orders/:order_id/order_details/:id
  def edit
  end

  # Put /orders/:order_id/order_details/:id
  def update
    if @order_detail.update_attributes(order_detail_params)
      flash[:notice] = I18n.t("order_details.update.success")
      redirect_to action: :show
    else
      flash.now[:error] = I18n.t("order_details.update.failure")
      render :edit
    end
  end

  # PUT /orders/:order_id/order_details/:id/cancel
  def cancel
    # handle reservation cancellation
    if @order_detail.reservation && @order_detail.reservation.can_cancel?
      @order_detail.transaction do
        if @order_detail.cancel_reservation(session_user)
          flash[:notice] = "The reservation has been canceled successfully." # TODO: I18n
        else
          flash[:error] = "An error was encountered while canceling the order." # TODO: I18n
          raise ActiveRecord::Rollback
        end
      end
      redirect_to(reservations_path)
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  # PUT /orders/:order_id/order_details/:id/dispute
  def dispute
    raise ActiveRecord::RecordNotFound unless @order_detail.can_dispute?

    @order_detail.transaction do
      begin
        @order_detail.dispute_reason = params[:order_detail][:dispute_reason]
        @order_detail.dispute_at = Time.zone.now
        @order_detail.dispute_by = current_user
        @order_detail.save!
        flash[:notice] = "Your purchase has been disputed" # TODO: I18n
        return_path = @order_detail.reservation ? reservations_path : orders_path
        redirect_to return_path
      rescue => e # TODO: be more specific about what Exceptions to rescue
        flash.now[:error] = "An error was encountered while disputing the order." # TODO: I18n
        @order_detail.dispute_at = nil # manually set this because rollback doesn't reset the unsaved value
        @order_detail.send(:extend, PriceDisplayment)
        render :show
        raise ActiveRecord::Rollback
      end
    end
  end

  private

  def prevent_edit_based_on_state
    unless order_editable?
      flash[:notice] = I18n.t("order_details.edit.failure")
      redirect_to action: :show
    end
  end

  def order_editable?
    @order_detail.customer_account_changeable?
  end
  helper_method :order_editable?

  def init_order_detail
    @order = Order.find(params[:order_id])
    @order_detail = @order.order_details.find(params[:id] || params[:order_detail_id])
  end

  def set_active_tab
    @active_tab = @order_detail.reservation.nil? ? "orders" : "reservations"
  end

  def ability_resource
    @order_detail
  end

  def order_detail_params
    params.require(:order_detail).permit(:account_id)
  end

end
