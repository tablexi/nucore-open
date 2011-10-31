class TransactionHistoryController < ApplicationController
  include DateHelper
  
  before_filter :load_filter_options
  def index
    start_date = parse_usa_date(params[:start_date])
    end_date = parse_usa_date(params[:end_date])   
    @order_details = OrderDetail.
      ordered.
      for_accounts(params[:accounts]).
      for_facilities(params[:facilities]).
      in_date_range(start_date, end_date).
      joins(:order).
      order("orders.ordered_at DESC")
      
  end
  
  def load_filter_options
    @accounts = Account.active
    @facilities = Facility.active
  end
end
