class TransactionHistoryController < ApplicationController
  admin_tab     :all
  customer_tab :my_history, :account_history
  
  include DateHelper
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility, :only => [:facility_history]
  before_filter :init_current_account, :only => [:account_history]
  include TransactionSearch
   
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
  
  
  
end
