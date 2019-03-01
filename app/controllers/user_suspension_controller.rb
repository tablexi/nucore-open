# frozen_string_literal: true

class UserSuspensionController < ApplicationController

  admin_tab     :all
  before_action :init_current_facility
  before_action :authenticate_user!
  load_and_authorize_resource :user, id_param: :user_id

  # POST /facilities/facility_id/users/:id/suspension
  def create
    @user.suspended_at ||= Time.current
    @user.save!
    redirect_to facility_user_path(current_facility, @user), notice: text("create.success")
  end

  # DELETE /facilities/facility_id/users/:id/suspension
  def destroy
    @user.update!(suspended_at: nil)
    redirect_to facility_user_path(current_facility, @user), notice: text("destroy.success")
  end

end
