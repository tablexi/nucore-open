# frozen_string_literal: true

class GlobalUserRolesController < GlobalSettingsController

  before_action :load_user, only: [:destroy, :edit, :update]

  def index
    @users = User.with_global_roles
  end

  def destroy
    destroy_all_global_roles
    redirect_to global_user_roles_url
  end

  def edit
    if @user == current_user
      flash[:error] = translate("self_not_allowed", action: "change")
      redirect_to global_user_roles_url
    end
  end

  def search
  end

  def update
    case
    when params[:roles].blank?
      destroy_all_global_roles
    when @user == current_user
      flash[:error] = translate("self_not_allowed", action: "change")
    else
      assign_global_roles!
      flash[:notice] = translate("update.success", user: @user.username)
    end
  rescue ActiveRecord::RecordInvalid
    flash[:error] = translate("update.failure", user: @user.username)
  ensure
    redirect_to global_user_roles_url
  end

  private

  def assign_global_roles!
    @user.transaction do
      @user.user_roles.global.destroy_all
      params[:roles].each do |role_name|
        UserRole.create!(user: @user, role: role_name)
      end
    end
  end

  def destroy_all_global_roles
    case
    when @user == current_user
      flash[:error] = translate("self_not_allowed", action: "remove")
    when @user.user_roles.global.destroy_all
      flash[:notice] = translate("destroy.success", user: @user.username)
    else
      flash[:error] = translate("destroy.failure", user: @user.username)
    end
  end

  def load_user
    @user = User.find(params[:id])
  end

  def translate(key, arguments = {})
    I18n.t("global_user_roles.#{key}", arguments)
  end

end
