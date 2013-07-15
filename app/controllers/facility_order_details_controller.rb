class FacilityOrderDetailsController < ApplicationController
  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility
  before_filter :init_order_detail, :except => :remove_from_journal

  load_and_authorize_resource :class => OrderDetail

  include FacilityOrderStatusHelper
  helper_method :new_or_in_process_orders, :problem_orders, :disputed_orders

  def initialize
    @active_tab = 'admin_orders'
    super
  end

  # GET /facilities/:facility_id/orders/:order_id/order_details/:id/edit
  def edit
    set_active_tab
    @in_open_journal=@order_detail.journal && @order_detail.journal.open?

    condition=case @order_detail.account
      when NufsAccount
        (@order_detail.journal && @order_detail.journal.is_successful) || OrderDetail.need_journal.include?(@order_detail)
      else
        !@order_detail.statement.nil?
    end

    @can_be_reconciled=condition && @order_detail.complete? && !@order_detail.in_dispute?

    if @in_open_journal
      flash.now[:notice]=I18n.t 'controllers.facility_order_details.edit.notice.open_journal'
    elsif @order_detail.order_status.name == 'Complete'
      if @order_detail.reservation.try(:requires_but_missing_actuals?)
        flash.now[:notice]=I18n.t 'controllers.facility_order_details.edit.notice.no_actuals'
      elsif @order_detail.price_policy.nil?
        flash.now[:notice]=I18n.t 'controllers.facility_order_details.edit.notice.no_policy'
      end
    end

  end

  # PUT /facilities/:facility_id/orders/:order_id/order_details/:id
  def update
    unless @order_detail.state == 'new' || @order_detail.state == 'inprocess' || can?(:update, @order_detail)
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
            raise "Order # #{@order_detail} failed cancellation." unless @order_detail.cancel_reservation(session_user, os, true, params[:with_cancel_fee] == '1')
          # cancel other orders or change status of any order
          else
            @order_detail.change_status!(os)
          end
        end
        @order_detail.save!
        flash[:notice] = 'The order has been updated successfully'
        redirect_to(params[:return_to].present? ? params[:return_to] :
                    @order_detail.reservation ? timeline_facility_reservations_path(current_facility) :
                    facility_orders_path(current_facility)) and return
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
        redirect_to (@order_detail.reservation ? disputed_facility_reservations_path : disputed_facility_orders_path) and return
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
    qty           = params[:quantity].to_i

    cost    = qty * @order_detail.price_policy.unit_cost
    subsidy = qty * @order_detail.price_policy.unit_subsidy
    total   = cost - subsidy

    render :json => [cost, subsidy, total]
  end


  def remove_from_journal
    oid=params[:id]
    return redirect_to :back if oid.blank?

    od=OrderDetail.find(oid.to_i)

    OrderDetail.transaction do
      jr=JournalRow.where(:journal_id => od.journal_id, :order_detail_id => od.id).first
      jr.try :destroy
      od.update_attributes! :journal_id => nil
    end

    flash[:notice]=I18n.t 'controllers.facility_order_details.remove_from_journal.notice'
    redirect_to facility_order_path(current_facility, od.order)
  end


  def destroy
    if @order.to_be_merged?
      begin
        @order_detail.destroy
        flash[:notice]=I18n.t 'controllers.facility_order_details.destroy.success'
      rescue => e
        Rails.logger.error "#{e.message}:#{e.backtrace.join("\n")}"
        flash[:error]=I18n.t 'controllers.facility_order_details.destroy.error', @order_detail.to_s
      end
    else
      flash[:notice]=I18n.t 'controllers.facility_order_details.destroy.notice'
      return redirect_to facility_order_path(current_facility, @order)
    end

    redirect_to facility_order_path(current_facility, @order.merge_order)
  end


  private

  def process_account_change
    return if params[:order_detail][:account_id].to_i == @order_detail.account_id
    @order_detail.account=Account.find(params[:order_detail][:account_id])
    @order_detail.statement=nil
    @order_detail.save!
  end

  def set_active_tab
    if @order_detail.reservation
      @active_tab = "admin_reservations"
    else
      @active_tab = "admin_orders"
    end
  end

  def init_order_detail
    @order = Order.find(params[:order_id])
    raise ActiveRecord::RecordNotFound unless @order
    @order_detail = @order.order_details.find(params[:id] || params[:order_detail_id])
  end
end
