class GlobalUserRolesController < GlobalSettingsController

  def index
    @users = UserPresenter.wrap(User.with_global_roles)
  end

  def destroy
    user = User.find(params[:id])
    if user == current_user
      flash[:error] = t("global_user_roles.destroy.self_not_allowed")
    else
      user.user_roles.global.each(&:destroy)
      if user.user_roles.global.empty?
        flash[:notice] = t("global_user_roles.destroy.success", username: user.username)
      else
        flash[:error] = t("global_user_roles.destroy.failure", username: user.username)
      end
    end

    redirect_to global_user_roles_url
  end

  def search
  end

end
