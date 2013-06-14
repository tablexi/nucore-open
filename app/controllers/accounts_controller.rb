class AccountsController < ApplicationController
  customer_tab  :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_account, :only => [:show, :user_search, :transactions, :transactions_in_review, :suspend, :unsuspend ]

  include TransactionSearch
  include AccountSuspendActions
  load_and_authorize_resource :only => [:show, :user_search, :transactions, :transactions_in_review, :suspend, :unsuspend ]


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

  def transactions_with_search
    @order_details = @order_details.where(:account_id => @account.id)
    paginate_order_details
    @active_tab = 'accounts'
  end

  def transactions_in_review_with_search
    @order_details = @order_details.where(:account_id => @account.id)
    @recently_reviewed = @order_details.recently_reviewed.paginate(:page => params[:page])
    @order_details = @order_details.all_in_review

    @extra_date_column = :reviewed_at
    @order_detail_link = {
      :text => "Dispute",
      :display? => Proc.new {|order_detail| order_detail.can_dispute?},
      :proc => Proc.new {|order_detail| order_order_detail_path(order_detail.order, order_detail)}
    }
  end

  protected

  def init_account
    @account = Account.find(params[:id] || params[:account_id])
  end


  private

  def ability_resource
    return @account
  end
end
