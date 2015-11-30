class GlobalUserRolesController < GlobalSettingsController

  before_filter :load_user, only: [:destroy, :edit, :update]

  def index
    @users = UserPresenter.wrap(User.with_global_roles)
  end

  def destroy
    case
    when @user == current_user
      flash[:error] = translate("self_not_allowed", action: "remove")
    when @user.user_roles.global.destroy_all
      flash[:notice] = translate("destroy.success", user: @user.username)
    else
      flash[:error] = translate("destroy.failure", user: @user.username)
    end

    redirect_to global_user_roles_url
  end

  def edit
    @user = UserPresenter.new(@user)
  end

  def search
  end

  def update
    if @user == current_user
      flash[:error] = translate("self_not_allowed", action: "change")
    else
      assign_global_role!
      flash[:notice] =
        translate("update.success", user: @user.username, role: role_name)
    end
  rescue ActiveRecord::RecordInvalid
    flash[:error] =
      translate("update.failure", user: @user.username, role: role_name)
  ensure
    redirect_to global_user_roles_url
  end

  private

  def assign_global_role!
    @user.transaction do
      @user.user_roles.global.destroy_all
      UserRole.create!(user: @user, role: role_name)
    end
  end

  def load_user
    @user = User.find(params[:id])
  end

  def role_name
    @role_name ||= params[:user_role][:role]
  end

  def translate(key, arguments = {})
    I18n.t("global_user_roles.#{key}", arguments)
  end
end
