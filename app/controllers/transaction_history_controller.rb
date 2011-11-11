class TransactionHistoryController < ApplicationController
  customer_tab  :all
  
  include DateHelper
  before_filter :authenticate_user!
  before_filter :check_acting_as
  
  before_filter :load_filter_options
  # def index
    # do_search(params)
    # @order_details = @order_details.paginate(:page => params[:page])
  # end
#   
  def search
    if (params[:commit])
      p = {
        :facilities => Facility.urls_from_ids(params[:facilities]).join("-").presence || "all", 
        :start_date => (params[:start_date].presence || "all").gsub("/", "-"), 
        :end_date => (params[:end_date].presence || "all").gsub("/", "-")
      }
      if (@account)
        redirect_to account_transaction_history_search_path(p.merge({:account_id => @account.id})) 
      else
        account_str = get_accounts.join("-").presence || "all"
        p.merge!({ :accounts => account_str })
        redirect_to transaction_history_search_path(p)
      end
      return
    end
    
    @search_fields = {}
    @search_fields[:accounts] = get_accounts
    @search_fields[:facilities] =  Facility.ids_from_urls(split_by_hyphen(params[:facilities])) unless params[:facilities] == "all"
    @search_fields[:start_date] = params[:start_date] unless params[:start_date] == "all"
    @search_fields[:end_date] = params[:end_date] unless params[:end_date] == "all"
    do_search(@search_fields)
    
    # cut down on some n+1s
    @order_details = @order_details.includes(:order => :facility).includes(:account).includes(:product).includes(:order_status).includes(:reservation).includes(:order => :user)
    
    @order_details = @order_details.paginate(:page => params[:page])
  end
  
  def get_accounts
    if @account
      accounts = [@account]
    else
      accounts = params[:accounts].respond_to?(:each) ? params[:accounts] : split_by_hyphen(params[:accounts])
      allowed_search_accounts = @accounts.map {|a| a.id.to_s}
      unallowed = accounts - allowed_search_accounts
      accounts = accounts - unallowed
    end
    accounts
  end
  
  def do_search(search_params)
    puts "search: #{search_params}"
    @order_details = OrderDetail.joins(:order).ordered
    if search_params[:accounts].blank?
      @order_details = @order_details.for_accounts(@accounts)
    else
      @order_details = @order_details.for_accounts(search_params[:accounts])
    end
    
    start_date = parse_usa_date(search_params[:start_date].to_s.gsub("-", "/"))
    end_date = parse_usa_date(search_params[:end_date].to_s.gsub("-", "/"))  
    
    @order_details = @order_details.for_facilities(search_params[:facilities]).
      fulfilled_in_date_range(start_date, end_date).
      order_by_desc_nulls_first(:fulfilled_at)    
  end
     
  private
  
  # made this to handle nils and 'all' while keeping the above code cleaner
  def split_by_hyphen(str)
    return [] if str.nil? or str == "all"
    str.split("-")
  end
  
  def load_filter_options
    if (params[:account_id])
      @account = session_user.accounts.find(params[:account_id])
    else
      @accounts = session_user.accounts
    end 
    
    @facilities = Facility.active
  end
  
  def set_accounts(accounts)
    @accounts = accounts
  end
  
end
