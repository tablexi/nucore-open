class FacilityOrderDetailsController < ApplicationController
  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility

  load_and_authorize_resource :class => OrderDetail

  def initialize
    @active_tab = 'admin_orders'
    super
  end

  # GET /facilities/:facility_id/orders/:order_id/order_details/:id/edit
  def edit
    @order        = current_facility.orders.find(params[:order_id])
    @order_detail = @order.order_details.find(params[:id])

    if @order_detail.cancelled?
      redirect_to :action => :show
    elsif current_user.manager_of?(current_facility)
      render :edit
    else
      if @order_detail.state == 'new' || @order_detail.state == 'inprocess'
        render :edit
      else
        redirect_to :action => :show
      end
    end
  end

  # PUT /facilities/:facility_id/orders/:order_id/order_details/:id
  def update
    @order        = current_facility.orders.find(params[:order_id])
    @order_detail = @order.order_details.find(params[:id])

    unless @order_detail.state == 'new' || @order_detail.state == 'inprocess' || session_user.manager_of?(current_facility)
      raise ActiveRecord::RecordNotFound
    end

    @order_detail.transaction do
      begin
        # process account change
        process_account_change

        # process all changes except order status
        @order_detail.attributes = params[:order_detail].reject{|k, v| k == :order_status_id}
        @order_detail.actual_cost = params[:order_detail][:actual_cost].gsub(/[^\d\.]/,'')
        @order_detail.actual_subsidy = params[:order_detail][:actual_subsidy].gsub(/[^\d\.]/,'')
        @order_detail.updated_by = session_user.id
        @order_detail.save!

        # process order status change
        if params[:order_detail][:order_status_id]
          os = OrderStatus.find(params[:order_detail][:order_status_id])
          # cancel instrument orders
          if os.root == OrderStatus.cancelled.first && @order_detail.reservation
            raise "Order # #{@order_detail} failed cancellation." unless @order_detail.cancel_reservation(session_user, os, true)
          # cancel other orders or change status of any order
          else
            @order_detail.change_status!(os)
          end
        end
        @order_detail.save!
        flash[:notice] = 'The order has been updated successfully'
        if @order_detail.new? || @order_detail.inprocess? || @order_detail.cancelled?
          redirect_to facility_orders_path(current_facility) and return
        elsif @order_detail.reviewable?
          redirect_to review_facility_orders_path(current_facility) and return
        else
          redirect_to :action => 'show' and return
        end
      rescue Exception => e
        flash.now[:error] = 'An error was encounted while updating the order'
        raise ActiveRecord::Rollback
      end
    end
    render :action => 'edit'
  end

  # POST /facilities/:facility_id/orders/:order_id/order_details/:order_detail_id/resolve_dispute
  def resolve_dispute
    @order        = current_facility.orders.find(params[:order_id])
    @order_detail = @order.order_details.find(params[:order_detail_id])

    unless current_user.manager_of?(current_facility) && @order_detail.dispute_at && @order_detail.dispute_resolved_at.nil?
      raise ActiveRecord::RecordNotFound
    end

    @order_detail.transaction do
      begin
        # process account change
        process_account_change

        # process credit
        if @order_detail.dispute_resolved_credit && @order_detail.dispute_resolved_credit > 0
          @order_detail.current_purchase_account_transaction.resolve_dispute_with_credit!(@order_detail.dispute_resolved_credit, :created_by => session_user.id)
        end

        # resolve current purchase account transaction (in case no credit or move have adjusted it yet)
        current_txn = @order_detail.current_purchase_account_transaction
        current_txn.is_in_dispute = false
        if current_txn.statement_id && current_txn.statement.invoice_date > Time.zone.now
          current_txn.finalized_at = current_txn.statement.invoice_date
        else
          current_txn.statement_id = nil
        end
        current_txn.save! if current_txn.changed?

        # update order detail
        @order_detail.attributes          = params[:order_detail]
        @order_detail.updated_by          = session_user.id
        @order_detail.dispute_resolved_at = Time.zone.now
        @order_detail.save!

        flash[:notice] = 'The dispute has been resolved successfully'
        redirect_to disputed_facility_orders_path and return
      rescue Exception => e
        flash.now[:error] = "An error was encountered while resolving the dispute"
        raise ActiveRecord::Rollback
      end
    end
    @order_detail.dispute_resolved_at = nil #rollback does not reset the un-saved value, so have to manually set to the view will render correctly
    render :action => 'edit'
  end

  # GET /facilities/:facility_id/orders/:order_id/order_details/:id
  def show
    @order        = current_facility.orders.find(params[:order_id])
    @order_detail = @order.order_details.find(params[:id])
  end

  # GET /facilities/:facility_id/orders/:order_id/order_details/:order_detail_id/new_price
  def new_price
    @order        = current_facility.orders.find(params[:order_id])
    @order_detail = @order.order_details.find(params[:order_detail_id])
    qty           = params[:quantity].to_i

    cost    = qty * @order_detail.price_policy.unit_cost
    subsidy = qty * @order_detail.price_policy.unit_subsidy
    total   = cost - subsidy

    render :json => [cost, subsidy, total]
  end

  protected
  def process_account_change
    if (params[:order_detail][:account_id].to_i != @order_detail.account_id && @order_detail.state == 'complete')
      new_account = Account.find(params[:order_detail][:account_id])
      at = @order_detail.current_purchase_account_transaction
      at.is_in_dispute = false
      at.move_to_new_account!(new_account, :created_by => session_user.id)
    end
  end
end
