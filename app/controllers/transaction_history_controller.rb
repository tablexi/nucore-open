class TransactionHistoryController < ApplicationController
  #layout 'application'
  #layout 'two_column', :except => [:my_history, :account_history]
  admin_tab     :all
  customer_tab :my_history, :account_history
  
  include DateHelper
  before_filter :authenticate_user!
  before_filter :check_acting_as
  
  include TransactionSearch
  transaction_search :my_history, :account_history, :facility_history
   
  def my_history
    @accounts = session_user.accounts
    @facilities = Facility.active
    
    @search_fields = params.merge({
      :accounts => get_allowed_accounts(@accounts, params[:accounts])
    })
    do_search(@search_fields)
    add_optimizations
    @order_details = @order_details.paginate(:page => params[:page])
  end
  
  def account_history
    @accounts = Account.find_all_by_id(params[:account_id])
    @account = @accounts[0]
    
    @search_fields = params.merge({
      :accounts => [@account]
    })
    do_search(@search_fields)
    add_optimizations
    @order_details = @order_details.paginate(:page => params[:page])
    @active_tab = 'accounts'
  end
  
  def facility_history
    @order_details = @order_details.paginate(:page => params[:page])
    @active_tab = 'admin_billing'
    render :layout => 'two_column_head'
  end
  
end
