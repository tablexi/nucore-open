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
        # do the intersection with @accounts to remove any accounts they're not allowed to see
        account_ids = @accounts.map {|a| a.id.to_s}
        account_str = (((params[:accounts] || []) & account_ids).join("-")).presence || "all"
        p.merge!({ :accounts => account_str })
        redirect_to transaction_history_search_path(p)
      end
      return
    end
    params[:accounts] = [params[:account_id]] if params[:account_id]
    @search_fields = {}
    @search_fields[:accounts] = split_by_hyphen(params[:accounts]).presence || [] unless params[:accounts] == "all"
    @search_fields[:facilities] =  Facility.ids_from_urls(split_by_hyphen(params[:facilities])) unless params[:facilities] == "all"
    @search_fields[:start_date] = params[:start_date] unless params[:start_date] == "all"
    @search_fields[:end_date] = params[:end_date] unless params[:end_date] == "all"
    do_search(@search_fields)
    
    @order_details = @order_details.paginate(:page => params[:page])
    # save some SQL queries
    @order_details = @order_details.includes(:order => :facility).includes(:account).includes(:product).includes(:order_status).includes(:reservation)
  end
  
  def do_search(search_params)
    @order_details = OrderDetail.ordered
    if (@account)
      @order_details = @order_details.for_accounts([@account.id])
    else
      search = search_params[:accounts]
      allowed_search_accounts = @accounts.map {|a| a.id.to_s}
      if (search.nil? or search.empty?)
        search = allowed_search_accounts
      end
      @order_details = @order_details.for_accounts(search & allowed_search_accounts)
    end
    start_date = parse_usa_date(search_params[:start_date].to_s.gsub("-", "/"))
    end_date = parse_usa_date(search_params[:end_date].to_s.gsub("-", "/"))  
    
    @order_details = @order_details.joins(:order).for_facilities(search_params[:facilities]).
      in_date_range(start_date, end_date).
      order_by_desc_nulls_first(:fulfilled_at)    
  end
     
  private
  
  # made this to handle nils while keeping the above code cleaner
  def split_by_hyphen(str)
    return nil if str.nil?
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
