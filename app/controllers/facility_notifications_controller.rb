class FacilityNotificationsController < ApplicationController
  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility
  
  include TransactionSearch
  transaction_search :index, :in_review
  
  authorize_resource :manage, :class => Facility

  layout 'two_column_head'
  
  def initialize
    @active_tab = 'admin_billing'
    super
  end

  # GET /facilities/:facility_id/notifications
  def index
    @order_details = @order_details.need_notification(@facility)
    @order_detail_action = :send_notifications
  end
  
  def send_notifications
    @accounts_to_notify = []
    @orders_notified = []
    @errors = []
    reviewed_at = Time.zone.now + 7.days
    if params[:order_detail_ids].nil? or params[:order_detail_ids].empty?
      flash[:error] = "No #{Order.model_name.human.pluralize.downcase} selected"
      redirect_to :action => :index
      return
    end
    OrderDetail.transaction do
      params[:order_detail_ids].each do |order_detail_id|
        od = nil
        begin
          od = OrderDetail.need_notification(current_facility).find(order_detail_id, :readonly => false)
        rescue Exception => e
          @errors << "#{Order.model_name.human} #{order_detail_id} was either not found or has already been notified."
        end
        if od
          od.reviewed_at = reviewed_at
          @errors << "#{od} #{od.errors}" unless od.save
          @orders_notified << od
          @accounts_to_notify << od.account unless @accounts_to_notify.include?(od.account)
        end      
      end
      if @errors.any?
        flash[:error] = "We experienced the following errors. Pease try again.<br/> #{@errors.join('<br/>')}"
        raise ActiveRecord::Rollback
      else
        @accounts_to_notify.each do |account|
          account.notify_users.each {|u| Notifier.review_orders(:user => u, :facility => current_facility, :account => account).deliver }
        end
        account_list = @accounts_to_notify.map {|a| a.account_list_item }
        flash[:notice] = "Notifications sent successfully to:<br/> #{account_list.join('<br/>')}".html_safe
      end
    end
    redirect_to :action => :index
  end
  
  def in_review
    @order_details = @order_details.in_review(@facility)
    @order_details = @order_details.reorder(:reviewed_at)
    @order_detail_action = :mark_as_reviewed
    @extra_date_column = :reviewed_at
  end
  
  def mark_as_reviewed
    if params[:order_detail_ids].nil? or params[:order_detail_ids].empty?
      flash[:error] = 'No orders were selected'      
    else
      @errors = []
      @order_details_updated = []
      params[:order_detail_ids].each do |order_detail_id|
        begin
          od = OrderDetail.find(order_detail_id)
          od.reviewed_at = Time.zone.now
          od.save!
          @order_details_updated << od
        rescue Exception => e
          logger.error(e.message)
          @errors << order_detail_id
        end
      end
      flash[:notice] = "The select orders have been marked as reviewed" if @order_details_updated.any?
      flash[:error] = "An error was encountered while marking some orders as reviewed: #{@errors.join(', ')}" if @errors.any?
    end
    redirect_to :action => :in_review
  end


#
  # def in_review
    # if request.post?
      # if params[:order_detail_ids]
        # begin
          # order_details = OrderDetail.find(params[:order_detail_ids])
          # order_details.each do |od|
            # od.reviewed_at = Time.zone.now
            # od.save!
          # end
        # rescue Exception => e
          # flash.now[:error] = 'An error was encountered while marking some orders as reviewed'
        # end
        # flash.now[:notice] = 'The select orders have been marked as reviewed'
      # else
        # flash.now[:error] = 'No orders were selected'
      # end
    # end
    # @order_details = OrderDetail.in_review(current_facility)
  # end
end
