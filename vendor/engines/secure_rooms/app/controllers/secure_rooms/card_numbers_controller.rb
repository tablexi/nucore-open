module SecureRooms

  class CardNumbersController < ApplicationController

    include TextHelpers::Translation

    admin_tab :all
    customer_tab :password

    layout "two_column"

    before_action :init_current_facility
    before_action :authenticate_user!
    before_action :load_and_authorize_user_with_card_number
    before_action :check_acting_as

    def initialize
      @active_tab = "admin_users"
      super
    end

    def edit
    end

    def update
      if @user.update_attributes(update_user_params)
        flash[:notice] = text("controllers.users.update.success")
        redirect_to facility_user_path(current_facility, @user)
      else
        flash[:error] = text("controllers.users.update.error", message: @user.errors.full_messages.to_sentence)
        render action: :edit
      end
    end

    # During rendering, we want to use the Ability as if we were using the
    # UsersController within which this card number form is placed.
    def current_ability
      ::Ability.new(current_user, current_facility, UsersController.new)
    end

    private

    def update_user_params
      params.require(:user).permit(:card_number)
    end

    def load_and_authorize_user_with_card_number
      @user = User.find(params[:user_id])
      ability = SecureRooms::CardNumberAbility.new(current_user, current_facility)
      raise CanCan::AccessDenied unless ability.can? :edit, User
    end

  end

end
