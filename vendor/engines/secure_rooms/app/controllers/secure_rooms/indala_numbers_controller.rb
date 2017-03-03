module SecureRooms

  class IndalaNumbersController < ApplicationController

    include TextHelpers::Translation

    customer_tab :password
    admin_tab     :all

    layout "two_column"

    before_action :init_current_facility
    before_action :authenticate_user!
    before_action :custom_authorize
    before_action :check_acting_as

    def initialize
      @active_tab = "admin_users"
      super
    end

    def edit
      @user = User.find(params[:id])
    end

    def update
      @user = User.find(params[:id])
      if @user.update_attributes(update_user_params)
        flash[:notice] = text("controllers.users.update.success")
        redirect_to facility_user_path(current_facility, @user)
      else
        flash[:error] = text("controllers.users.update.error", message: @user.errors.full_messages.to_sentence)
        render action: :edit
      end
    end

    # During rendering, we want to use the Ability as if we were using the
    # UsersController within which this IndalaNumber form is placed.
    def current_ability
      Ability.new(current_user, current_facility, UsersController.new)
    end

    private def update_user_params
      params.require(:user).permit(:indala_number)
    end

    private def custom_authorize
      ability = SecureRooms::IndalaAbility.new(current_user, current_facility)
      head :not_authorized unless ability.can? :edit, User
    end

  end

end
