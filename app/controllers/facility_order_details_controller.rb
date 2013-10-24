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
