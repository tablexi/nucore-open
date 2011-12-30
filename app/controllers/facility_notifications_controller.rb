class FacilityNotificationsController < ApplicationController
  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility
  
  include TransactionSearch
  
  authorize_resource :manage, :class => Facility
  
  layout 'two_column_head'
  
  def initialize
    @active_tab = 'admin_billing'
    super
  end

  # GET /facilities/:facility_id/notifications
  def index_with_search
    @order_details = @order_details.all_need_notification
    @order_detail_action = :send_notifications
  end
  
  def send_notifications
    @accounts_to_notify = []
    @orders_notified = []
    @errors = []
    reviewed_at = Time.zone.now + 7.days
    if params[:order_detail_ids].nil? or params[:order_detail_ids].empty?
      flash[:error] = I18n.t 'controllers.facility_notifications.no_selection'
      redirect_to :action => :index
      return
    end
    OrderDetail.transaction do
      params[:order_detail_ids].each do |order_detail_id|
        od = nil
        begin
          od = OrderDetail.need_notification(current_facility).find(order_detail_id, :readonly => false)
        rescue Exception => e
          @errors << I18n.t('controllers.facility_notifications.send_notifications.order_error', :order_detail_id => order_detail_id)
        end
        if od
          od.reviewed_at = reviewed_at
          @errors << "#{od} #{od.errors}" unless od.save
          @orders_notified << od
          @accounts_to_notify << od.account unless @accounts_to_notify.include?(od.account)
        end      
      end
      if @errors.any?
        flash[:error] = I18n.t('controllers.facility_notifications.errors_html', :errors => @errors.join('<br/>')).html_safe
        raise ActiveRecord::Rollback
      else
        @accounts_to_notify.each do |account|
          account.notify_users.each {|u| Notifier.review_orders(:user => u, :facility => current_facility, :account => account).deliver }
        end
        account_list = @accounts_to_notify.map {|a| a.account_list_item }
        flash[:notice] = I18n.t('controllers.facility_notifications.send_notifications.success_html', :accounts => account_list.join('<br/>')).html_safe
      end
    end
    redirect_to :action => :index
  end
  
  def in_review_with_search
    @order_details = @order_details.all_in_review
    @order_details = @order_details.reorder(:reviewed_at)
    @order_detail_action = :mark_as_reviewed
    @extra_date_column = :reviewed_at
  end
  
  
  def mark_as_reviewed
    if params[:order_detail_ids].nil? or params[:order_detail_ids].empty?
      flash[:error] = I18n.t 'controllers.facility_notifications.no_selection'      
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
      flash[:notice] = I18n.t('controllers.facility_notifications.mark_as_reviewed.success') if @order_details_updated.any?
      flash[:error] = I18n.t('controllers.facility_notifications.mark_as_reviewed.errors', :errors =>  @errors.join(', ')) if @errors.any?
    end
    redirect_to :action => :in_review
  end

end
