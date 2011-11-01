class TransactionHistoryController < ApplicationController
  include DateHelper
  before_filter :authenticate_user!
  before_filter :check_acting_as
  
  before_filter :load_filter_options
  def index
    start_date = parse_usa_date(params[:start_date])
    end_date = parse_usa_date(params[:end_date])   
    @order_details = OrderDetail.ordered
    if (@account)
      @order_details = @order_details.for_accounts([@account.id])
    else
      @order_details = @order_details.for_accounts(params[:accounts])
    end
    @order_details = @order_details.for_facilities(params[:facilities]).
      in_date_range(start_date, end_date).
      joins(:order).
      order("orders.ordered_at DESC")
      
    @order_details = @order_details.paginate(:page => params[:page])
  end
  
  def load_filter_options
    if (params[:account_id])
      @account = session_user.accounts.find(params[:account_id])
    else
      @accounts = Account.active
    end 
    
    @facilities = Facility.active
  end
end
