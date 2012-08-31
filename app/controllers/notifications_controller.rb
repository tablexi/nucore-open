class NotificationsController < ApplicationController
  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :check_notifications

  #respond_to :js, :only => :update


  def index
  end

  #
  # Currently not routed to, but if you want to allow
  # dismissal of notifications you should enable this action
  #def update
  #  begin
  #    notice=Notification.find params[:id].to_i
  #    notice.update_attribute :dismissed_at, Time.zone.now
  #  rescue => e
  #    Rails.logger.warn "#{e.message}\n#{e.backtrace.join("\n")}"
  #  end
  #
  #  respond_with nil
  #end


  private

  def check_notifications
    @notices=current_user.notifications.active.all

    if @notices.count == 0
      flash[:notice]=I18n.t 'controllers.notifications.no_notices'

      begin
        redirect_to :back
      rescue ActionController::RedirectBackError
        redirect_to root_path
      end
    end
  end

end
