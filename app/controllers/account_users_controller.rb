class AccountUsersController < ApplicationController
  customer_tab  :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_account

  load_and_authorize_resource

  def initialize
    @active_tab = 'accounts'
    super
  end
  
  # GET /accounts/:account_id/account_users/user_search
  def user_search
  end

  # GET /accounts/:account_id/account_users/new
  def new
    @user         = User.find(params[:user_id])
    @account_user = AccountUser.new
  end

  # POST /accounts/:account_id/account_users
  def create
    ## TODO add security
    @user                    = User.find(params[:user_id])
    @account_user            = @account.account_users.new(params[:account_user])
    @account_user.user       = @user
    @account_user.created_by = session_user.id

    if @account_user.save
      flash[:notice] = "#{@user.full_name} was added to the #{@account.type_string} Account"
      redirect_to account_account_users_path(@account)
    else
      flash.now[:error] = "An error was encountered while trying to add #{@user.full_name} to the #{@account.type_string} Account"
      render :new
    end
  end

  # DELETE /accounts/:account_id/account_users/:id
  def destroy
    ## TODO add security
    @account_user = @account.account_users.find(params[:id])
    @account_user.deleted_at = Time.zone.now
    @account_user.deleted_by = session_user.id

    if @account_user.save
      flash[:notice] = "The user was successfully removed from the payment method"
    else
      flash[:error] = "An error was encountered while attempting to remove the user from the payment method"
    end
    redirect_to account_account_users_path(@account)
  end


  protected

  def init_account
    @account = session_user.accounts.find(params[:account_id])
  end


  private

  def ability_resource
    return @account
  end
end