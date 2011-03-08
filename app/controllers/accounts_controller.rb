class AccountsController < ApplicationController
  customer_tab  :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_account, :only => [:show, :user_search ]

  load_and_authorize_resource :only => [:show, :user_search ]


  def initialize
    @active_tab = 'accounts'
    super
  end

  # GET /accounts
  def index
    @account_users = session_user.account_users.active
  end

  # GET /accounts/1
  def show
  end

  # GET /accounts/1/user_search
  def user_search
    render(:template => "account_users/user_search")
  end

  protected
  
  def init_account
    @account = session_user.accounts.find(params[:id] || params[:account_id])
  end


  private

  def ability_resource
    return @account
  end
end
