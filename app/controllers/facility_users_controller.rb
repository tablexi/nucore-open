class FacilityUsersController < ApplicationController
  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility

  load_and_authorize_resource :class => User

  layout 'two_column'

  def initialize 
    @active_tab = 'admin_facility'
    super
  end

  # GET /facilities/:facility_id/facility_users
  def index
    @users = User.find_users_by_facility(current_facility)
  end

  # DELETE /facilities/:facility_id/facility_users/:facility_user_id/map_user
  # remove the user's facility-role mapping
  def destroy
    @user = User.find(params[:id])
    @user.facility_user_roles(current_facility).each {|r| r.destroy }
    redirect_to facility_facility_users_url
  end

  def search
  end

  # GET /facilities/:facility_id/facility_users/:facility_user_id/map_user
  def map_user
    @user = User.find(params[:facility_user_id])

    if request.request_method == :post
      begin
        @user_role=UserRole.grant(@user, params[:user_role], current_facility)
        redirect_to facility_facility_users_url
      rescue ActiveRecord::RecordInvalid
        render :action => "map_user"
      end
    end
  end 
end
