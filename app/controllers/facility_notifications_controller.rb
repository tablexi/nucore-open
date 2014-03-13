class FacilityNotificationsController < ApplicationController
  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as

  before_filter :init_current_facility
  before_filter :check_billing_access

  before_filter :check_review_period

  include TransactionSearch

  layout 'two_column_head'

  def initialize
    @active_tab = 'admin_billing'
    super
  end

  def check_review_period
    raise ActionController::RoutingError.new('Notifications disabled with a zero-day review period') unless SettingsHelper::has_review_period?
  end

  # GET /facilities/notifications
  def index_with_search
    @order_details = @order_details.all_need_notification
    @order_detail_action = :send_notifications
  end

  # GET /facilities/notifications/send
  def send_notifications
    @accounts_to_notify = []
    @orders_notified = []
    @errors = []
    reviewed_at = Time.zone.now + Settings.billing.review_period
    if params[:order_detail_ids].nil? or params[:order_detail_ids].empty?
      flash[:error] = I18n.t 'controllers.facility_notifications.no_selection'
      redirect_to :action => :index
      return
    end
    OrderDetail.transaction do
      params[:order_detail_ids].each do |order_detail_id|
        od = nil
        begin
          od = OrderDetail.for_facility(current_facility).need_notification.find(order_detail_id, :readonly => false)
        rescue => e
          @errors << I18n.t('controllers.facility_notifications.send_notifications.order_error', :order_detail_id => order_detail_id)
        end
        if od
          od.reviewed_at = reviewed_at
          @errors << "#{od} #{od.errors}" unless od.save

          if Settings.billing.review_period > 0
            @orders_notified << od
            @accounts_to_notify << [od.account, od.product.facility] unless @accounts_to_notify.include?([od.account, od.product.facility])
          end
        end
      end

      if @errors.any?
        flash[:error] = I18n.t('controllers.facility_notifications.errors_html', :errors => @errors.join('<br/>')).html_safe
        raise ActiveRecord::Rollback
      else
        notify_accounts
        account_list = @accounts_to_notify.map {|a, f| a.account_list_item }
        flash[:notice] = send_notification_success_message(account_list)
      end
    end
    redirect_to :action => :index
  end

  # GET /facilities/notifications/in_review
  def in_review_with_search
    @order_details = @order_details.all_in_review
    @order_details = @order_details.reorder(:reviewed_at)
    @order_detail_action = :mark_as_reviewed
    order_details_sort(:reviewed_at)
    @extra_date_column = :reviewed_at
  end

  # GET /facilities/notifications/in_review/mark
  def mark_as_reviewed
    if params[:order_detail_ids].nil? or params[:order_detail_ids].empty?
      flash[:error] = I18n.t 'controllers.facility_notifications.no_selection'
    else
      @errors = []
      @order_details_updated = []
      params[:order_detail_ids].each do |order_detail_id|
        begin
          od = OrderDetail.for_facility(current_facility).find(order_detail_id, :readonly => false)
          od.reviewed_at = Time.zone.now
          od.save!
          @order_details_updated << od
        rescue => e
          logger.error(e.message)
          @errors << order_detail_id
        end
      end
      flash[:notice] = I18n.t('controllers.facility_notifications.mark_as_reviewed.success') if @order_details_updated.any?
      flash[:error] = I18n.t('controllers.facility_notifications.mark_as_reviewed.errors', :errors =>  @errors.join(', ')) if @errors.any?
    end
    redirect_to :action => :in_review
  end

private

  def notify_accounts
    @accounts_to_notify.each do |account, facility|
      account.notify_users.each do |u|
        Notifier.review_orders(:user => u, :facility => facility, :account => account).deliver
      end
    end
  end

  def send_notification_success_message(account_list)
    if account_list.size > 10
      I18n.t('controllers.facility_notifications.send_notifications.success_count', :accounts => account_list.size)
    else
      I18n.t('controllers.facility_notifications.send_notifications.success_html', :accounts => account_list.join('<br/>')).html_safe
    end
  end
end
