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
            flash[:notice] = 'Notifications sent successfully'
          end
        end
      else
        flash[:error] = 'No payment sources selected'
      end
    end

    # select * from order_details where state = completed and reviewed_at = nil and disputed_on = nil and disputed 
    @accounts = Account.need_notification(current_facility)
  end
end
