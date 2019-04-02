# frozen_string_literal: true

class UserAccountsController < ApplicationController
  admin_tab :all
  before_action :init_current_facility
  layout "two_column"
  load_and_authorize_resource class: "User", id_param: :user_id, instance_name: :user

  def show
    @active_tab = "admin_users"
    @accounts = @user.accounts.for_facility(current_facility)
  end

  def edit
    @active_tab = "admin_users"
    @accounts = @user.accounts.for_facility(current_facility)
  end

  def update
    @active_tab = "admin_users"
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
