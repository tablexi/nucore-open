class FacilityNotificationsController < ApplicationController
  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility

  authorize_resource :class => Statement

  layout 'two_column'

  def initialize
    @active_tab = 'admin_invoices'
    super
  end

  # GET/POST /facilities/:facility_id/notifications
  def index
    if request.post?
      if params[:account_ids]
        accounts    = Account.find(params[:account_ids])
        error       = false
        reviewed_at = Time.zone.now + 7.days
        accounts.each do |a|
          a.transaction do
            begin
              details = a.order_details.need_notification(current_facility)
              unless details.empty?
                a.notify_users.each {|u| Notifier.deliver_review_orders(:user => u, :facility => current_facility, :account => a)}
                a.order_details.need_notification(current_facility).each do |od|
                  od.reviewed_at = reviewed_at
                  raise ActiveRecord::Rollback unless od.save
                end
              end
            rescue Exception => e
              flash.now[:error] = "An error was encountered while sending some notification emails"
              error = true
              raise ActiveRecord::Rollback
            end
            flash.now[:notice] = 'Notifications sent successfully'
          end
        end
      else
        flash.now[:error] = 'No payment sources selected'
      end
    end

    # select * from order_details where state = completed and reviewed_at = nil and disputed_on = nil and disputed 
    @accounts = Account.need_notification(current_facility)
  end

  def in_review
    if request.post?
      if params[:order_detail_ids]
        begin
          order_details = OrderDetail.find(params[:order_detail_ids])
          order_details.each do |od|
            od.reviewed_at = Time.zone.now
            od.save!
          end
        rescue Exception => e
          flash.now[:error] = 'An error was encountered while marking some orders as reviewed'
        end
        flash.now[:notice] = 'The select orders have been marked as reviewed'
      else
        flash.now[:error] = 'No orders were selected'
      end
    end
    @order_details = OrderDetail.in_review(current_facility)
  end
end
