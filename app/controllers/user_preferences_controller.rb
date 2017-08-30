class UserPreferencesController < ApplicationController

  before_action :authenticate_user!
  before_action :check_acting_as

  def index
  end

  def edit
    @user_preference = UserPreference.find params[:id]
  end

  def update
    @user_preference = UserPreference.find params[:id]
    if @user_preference.update_attributes(value: params[:user_preference][:value])
      redirect_to user_user_preferences_path(current_user)
    else
      render :edit
    end
  end

end
