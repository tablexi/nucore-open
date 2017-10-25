class NotificationsController < ApplicationController

  customer_tab  :all
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :check_notifications

  def index
  end

  private

  def check_notifications
    @notices = current_user.notifications.active

    if @notices.none?
      flash[:notice] = I18n.t "controllers.notifications.no_notices"

      begin
        redirect_to :back
      rescue ActionController::RedirectBackError
        redirect_to root_path
      end
    end
  end

end
