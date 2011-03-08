class FacilityAccountUsersController < ApplicationController
  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility

  load_and_authorize_resource :class => AccountUser

  layout 'two_column'

  def initialize
    @active_tab = 'admin_invoices'
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
    @account_user = AccountUser.new
  end

  # POST /facilities/:facility_id/accounts/:account_id/account_users
  def create
    @account                 = Account.find(params[:account_id])
    @user                    = User.find(params[:user_id])
    @account_user            = @account.account_users.new(params[:account_user])
    @account_user.user       = @user
    @account_user.created_by = session_user.id

    if @account_user.save
      flash[:notice] = "#{@user.full_name} was added to the #{@account.type_string} Account"
      redirect_to facility_account_members_path(current_facility, @account)
    else
      flash.now[:error] = "An error was encountered while trying to add #{@user.full_name} to the #{@account.type_string} Account"
      render(:action => 'new')
    end
  end

  # DELETE /facilities/:facility_id/accounts/:account_id/account_users/:id
  def destroy
    @account      = Account.find(params[:account_id])
    @account_user = @account.account_users.find(params[:id])
    @account_user.deleted_at = Time.zone.now
    @account_user.deleted_by = session_user.id

    if @account_user.save
      flash[:notice] = "The user was successfully removed from the payment method"
    else
      flash[:error] = "An error was encountered while attempting to remove the user from the payment method"
    end
    redirect_to facility_account_members_path(current_facility, @account)
  end
end