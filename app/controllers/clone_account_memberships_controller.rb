class CloneAccountMembershipsController < ApplicationController

  admin_tab :all
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_current_facility
  before_action :init_user
  before_action :user_to_clone, only: :new
  before_action :account_users, only: :new
  before_action { @active_tab = "accounts" }

  layout -> { request.xhr? ? false : "two_column" }

  def index
  end

  def search
    @users, _count = UserFinder.search(params[:search_term])

    render :search
  end

  def new
  end

  def create
    cloner = account_membership_cloner

    if cloner.perform
      flash[:notice] = t(:success, scope: "forms.clone_account_membership")

      redirect_to facility_user_accounts_path
    else
      flash[:error] = t(
        :error,
        scope: "forms.clone_account_membership",
        account_description: cloner.error.record.account.description,
        message: cloner.error.message
      )

      redirect_to new_facility_user_clone_account_membership_path(user_to_clone_id: user_to_clone.id)
    end
  end

  private

  def init_user
    @user = User.find(params[:user_id])
  end

  def user_to_clone
    @user_to_clone = User.find(params[:user_to_clone_id])
  end

  def account_users
    @account_users = AccountUser.where(user: user_to_clone).where.not(account: init_user.accounts)
  end

  def clone_account_membership_params
    params.permit(:user_to_clone_id, :account_user_ids =>[])
  end

  def account_membership_cloner
    AccountMembershipCloner.new(
      account_users_to_clone: account_users_to_clone,
      clone_to_user: init_user
    )
  end

  def account_users_to_clone
    AccountUser.where(id: clone_account_membership_params[:account_user_ids])
  end

end
