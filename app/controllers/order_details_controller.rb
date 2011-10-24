class OrderDetailsController < ApplicationController
  customer_tab  :all
  
  before_filter :authenticate_user!
  before_filter :check_acting_as,  :except => [:order_file, :upload_order_file, :remove_order_file]
  before_filter :init_order_detail

  def initialize
    @active_tab = 'orders'
    super
  end

  # PUT /orders/:order_id/order_details/:id
  def update
    # handle reservation cancellation
    if params[:cancel] && @order_detail.reservation && @order_detail.reservation.can_cancel?
      @order_detail.transaction do
        if @order_detail.cancel_reservation(session_user)
          flash[:notice] = "The reservation has been cancelled successfully."
        else
          flash[:error] = "An error was encountered while cancelling the order."
          raise ActiveRecord::Rollback
        end
      end
      redirect_to reservations_path and return

    # handle order disputes
    elsif @order_detail.can_dispute?
      @order_detail.transaction do
        begin
          @order_detail.dispute_reason = params[:order_detail][:dispute_reason]
          @order_detail.dispute_at = Time.zone.now
          @order_detail.save!
          flash[:notice] = 'Your purchase has been disputed'
          redirect_to orders_path and return
        rescue Exception => e
          flash.now[:error] = "An error was encountered while disputing the order."
          raise ActiveRecord::Rollback
        end
      end
      @order_detail.dispute_at = nil #rollback does not reset the un-saved value, so have to manually set to the view will render correctly
      render :show and return
    end
    raise ActiveRecord::RecordNotFound
  end
  
  # GET /orders/:order_id/order_details/:id
  def show
  end
  
  def init_order_detail
    @order = Order.find(params[:order_id])
    @order_detail = @order.order_details.find(params[:id] || params[:order_detail_id])
    raise ActiveRecord::RecordNotFound unless @order.user_id == acting_user.id || @order_detail.account.owner_user.id = @order.user_id || @order_detail.account.business_admins.any?{|u| u.id = @order.user_id} 
  end

  # GET /orders/:order_id/order_details/:order_detail_id/order_file
  def order_file
    raise ActiveRecord::RecordNotFound if @order_detail.product.file_uploads.template.empty?
    @file = @order_detail.file_uploads.new(:file_type => 'template_result')
  end

  # POST /orders/:order_id/order_details/:order_detail_id/upload_order_file
  def upload_order_file
    @file = @order_detail.file_uploads.new(params[:file_upload])
    @file.file_type  = 'template_result'
    @file.name       = 'Order File'
    @file.created_by = session_user.id ## this is correct, session_user instead of acting_user

    if @file.save
      flash[:notice] = 'Order File uploaded successfully'
      redirect_to(order_path(@order))
    else
      flash.now[:error] = 'An error was encountered while uploading the Order File'
      render :order_file
    end
  end

  # GET /orders/:order_id/order_details/:order_detail_id/remove_order_file
  def remove_order_file
    if @order_detail.file_uploads.template_result.all? {|file| file.destroy}
      flash[:notice] = 'The uploaded Order File has been deleted successfully'
    else
      flash[:error] = 'An error was encountered while deleting the uploaded Order File'
    end
    @order.invalidate!
    redirect_to(order_path(@order))
  end
end