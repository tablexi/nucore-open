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
    @order        = Order.find_by_id_and_facility_id(params[:order_id], current_facility.id)
    @order_detail = @order.order_details.find(params[:id])
    @in_open_journal=@order_detail.journal && @order_detail.journal.open?

    condition=case @order_detail.account
      when NufsAccount
        (@order_detail.journal && @order_detail.journal.is_successful) || OrderDetail.need_journal(current_facility).include?(@order_detail)
      else
        !@order_detail.statement.nil?
    end

    @can_be_reconciled=condition && @order_detail.complete? && !@order_detail.in_dispute?

    if @in_open_journal
      flash.now[:notice]="You are unable to edit all aspects of this order because it is part of a pending journal. Please close the journal first."
    elsif @order_detail.order_status.name == 'Complete'
      if @order_detail.reservation.try(:requires_but_missing_actuals?)
        flash.now[:notice]="This order's reservation does not have an actual time. Please ensure that actual times are set and there is a price policy for the date this order was fulfilled. Clicking 'Save' will attempt to assign a price policy to this order and save any other changes."
      elsif @order_detail.price_policy.nil?
        flash.now[:notice]="This order does not have a price policy assigned. Please ensure that there is a price policy for the date this order was fulfilled. Clicking 'Save' will attempt to assign a price policy to this order and save any other changes."
      end
    end
  end

  # PUT /facilities/:facility_id/orders/:order_id/order_details/:id
  def update
    @order        = Order.find(params[:order_id])
    @order_detail = @order.order_details.find(params[:id])

    unless @order_detail.state == 'new' || @order_detail.state == 'inprocess' || session_user.manager_of?(current_facility)
      raise ActiveRecord::RecordNotFound
    end

    @order_detail.transaction do
      begin
        # process account change
        process_account_change

        od_params=params[:order_detail]

        # process all changes except order status
        @order_detail.attributes = od_params.reject{|k, v| k == :order_status_id}
        @order_detail.actual_cost = od_params[:actual_cost].gsub(/[^\d\.]/,'') if od_params[:actual_cost]
        @order_detail.actual_subsidy = od_params[:actual_subsidy].gsub(/[^\d\.]/,'') if od_params[:actual_subsidy]
        @order_detail.updated_by = session_user.id
        @order_detail.reconciled_note=od_params[:reconciled_note] if od_params[:reconciled_note]

        if params[:assign_price_policy]
          @order_detail.assign_price_policy
        elsif @order_detail.price_policy.nil?
          @order_detail.assign_estimated_price
        end

        @order_detail.save!

        # process order status change
        if od_params[:order_status_id]
          os = OrderStatus.find(od_params[:order_status_id])
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
        elsif @order_detail.complete?
          redirect_to show_problems_facility_orders_path(current_facility) and return
        end
      rescue Exception => e
        flash.now[:error] = 'An error was encounted while updating the order'
        Rails.logger.warn "#{e.message}\n#{e.backtrace.join("\n")}"
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

        # update order detail
        @order_detail.attributes          = params[:order_detail]
        @order_detail.updated_by          = session_user.id
        @order_detail.dispute_resolved_at = Time.zone.now
        @order_detail.reviewed_at         = Time.zone.now
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


  def remove_from_journal
    oid=params[:id]
    return redirect_to :back unless oid

    oid=oid.to_i
    od=OrderDetail.find(oid)
    od.journal=nil
    od.save!

    flash[:notice]='The order has been removed from its journal'
    redirect_to edit_facility_order_order_detail_path(current_facility, od.order, od)
  end
  

  private

  def process_account_change
    return if params[:order_detail][:account_id].to_i == @order_detail.account_id
    @order_detail.account=Account.find(params[:order_detail][:account_id])
    @order_detail.statement=nil
    @order_detail.save!
  end

end
