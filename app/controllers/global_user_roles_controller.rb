class GlobalUserRolesController < GlobalSettingsController

  def index
    @users = UserPresenter.wrap(User.with_global_roles)
  end

  def destroy
    user = User.find(params[:id])
    if (user == current_user)
      flash[:error] = "nope"
    else
      user.user_roles.global.each(&:destroy)
      flash[:notice] = "yep"
    end

    redirect_to global_user_roles_url
  end

end
