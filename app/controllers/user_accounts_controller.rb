# frozen_string_literal: true

class UserAccountsController < ApplicationController
  admin_tab :all
  layout "two_column"

  before_action :init_current_facility
  load_resource class: "User", id_param: :user_id, instance_name: :user
  authorize_resource class: AccountUser
  before_action { @active_tab = "admin_users" }

  def show
    @accounts = @user.accounts.for_facility(current_facility)
  end

  def edit
    @accounts = @user.accounts.for_facility(current_facility)
  end

  def update
    if @user.update(user_params)
      redirect_to facility_user_accounts_path(current_facility, @user), flash: { notice: t(".updated", user_name: @user.full_name) }
    else
      flash.now[:error] = t(".could_not_update", user_name: @user.full_name)
      render :edit
    end
  end

  private

  def user_params
    params.require(:user).permit(accounts_attributes: [:id, :_destroy])
  end
end
