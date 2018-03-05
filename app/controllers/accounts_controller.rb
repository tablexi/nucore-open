class AccountsController < ApplicationController

  customer_tab  :all
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_account, only: [:show, :user_search, :transactions, :suspend, :unsuspend]

  include TransactionSearch
  include AccountSuspendActions
  load_and_authorize_resource only: [:show, :user_search, :transactions, :suspend, :unsuspend]

  def initialize
    @active_tab = "accounts"
    super
  end

  # GET /accounts
  def index
    @account_users = session_user.account_users
    @administered_order_details_in_review = current_user.administered_order_details.in_review
  end

  # GET /accounts/1
  def show
  end

  # GET /accounts/1/user_search
  def user_search
    render(template: "account_users/user_search")
  end

  def transactions_with_search
    set_default_start_date
    @order_details = @order_details.where(account_id: @account.id)
    @export_enabled = true
    paginate_order_details
    @active_tab = "accounts"
  end

  protected

  def init_account
    @account = Account.find(params[:id] || params[:account_id])
  end

  private

  def ability_resource
    @account
  end

end
