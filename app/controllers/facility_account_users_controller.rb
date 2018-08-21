# frozen_string_literal: true

class FacilityAccountUsersController < ApplicationController

  admin_tab     :all
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_current_facility

  load_and_authorize_resource class: AccountUser

  layout "two_column"

  helper_method :current_owner?

  def initialize
    @active_tab = "admin_billing"
    super
  end

  # GET /facilities/:facility_id/accounts/:account_id/account_users/user_search
  def user_search
    @account = Account.find(params[:account_id])
  end

  # GET /facilities/:facility_id/accounts/:account_id/account_users/new
  def new
    @account      = Account.find(params[:account_id])
    @user         = User.find(params[:user_id])
    role = current_owner? ? AccountUser::ACCOUNT_OWNER : AccountUser::ACCOUNT_PURCHASER
    @account_user = AccountUser.new(user_role: role)
  end

  # POST /facilities/:facility_id/accounts/:account_id/account_users
  def create
    @account = Account.find(params[:account_id])
    @user = User.find(params[:user_id])
    role = create_params[:user_role]

    @account_user = @account.add_or_update_member(@user, role, session_user)
    # account owner might've changed by earlier operation... reload it
    @account.reload

    if @account.errors.any?
      flash.now[:error] = "An error was encountered while trying to add #{@user.full_name} to the #{@account.type_string} Account"
      render(action: "new")
    else
      flash[:notice] = "#{@user.full_name} was added to the #{@account.type_string} Account"
      LogEvent.log(@account_user, :create, current_user)
      Notifier.user_update(account: @account, user: @user, created_by: session_user).deliver_now
      redirect_to facility_account_members_path(current_facility, @account)
    end
  end

  # DELETE /facilities/:facility_id/accounts/:account_id/account_users/:id
  def destroy
    @account      = Account.find(params[:account_id])
    @account_user = @account.account_users.find(params[:id])
    @account_user.deleted_at = Time.zone.now
    @account_user.deleted_by = session_user.id

    if @account_user.save
      LogEvent.log(@account_user, :delete, current_user)
      flash[:notice] = "The user was successfully removed from the payment method"
    else
      flash[:error] = "An error was encountered while attempting to remove the user from the payment method"
    end
    redirect_to facility_account_members_path(current_facility, @account)
  end

  private

  def create_params
    params.require(:account_user).permit(:user_role)
  end

  def current_owner?
    @account.owner_user == @user
  end

end
