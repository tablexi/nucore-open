class TransactionHistoryController < ApplicationController
  customer_tab  :all
  
  include DateHelper
  before_filter :authenticate_user!
  before_filter :check_acting_as
  
  #before_filter :load_filter_options
  before_filter :remove_ugly_params
  
  #def search
    
#     
    # @search_fields = {}
    # @search_fields[:accounts] = get_accounts
    # @search_fields[:facilities] = params[:facilities] unless params[:facilities] == "all" # Facility.ids_from_urls(split_by_hyphen(params[:facilities])) unless params[:facilities] == "all"
    # @search_fields[:start_date] = params[:start_date] unless params[:start_date] == "all"
    # @search_fields[:end_date] = params[:end_date] unless params[:end_date] == "all"
    # do_search(@search_fields)
    # add_optimizations
    # @order_details = @order_details.paginate(:page => params[:page])
  #  account_history
    
  #end
  
  def my_history
    @accounts = session_user.accounts
    @facilities = Facility.active
    
    @search_fields = {}
    @search_fields[:accounts] = get_my_accounts(@accounts, params[:accounts])
    @search_fields[:start_date] = params[:start_date].presence
    @search_fields[:end_date] = params[:end_date].presence
    @search_fields[:facilities] = params[:facilities]
    do_search(@search_fields)
    add_optimizations
    @order_details = @order_details.paginate(:page => params[:page])
  end
  
  def account_history
    @account = Account.find(params[:account_id])
    @accounts = [@account]
    @facilities = @account.facilities
    
    @search_fields = {}
    @search_fields[:accounts] = [@account]
    @search_fields[:start_date] = params[:start_date].presence
    @search_fields[:end_date] = params[:end_date].presence
    @search_fields[:facilities] = params[:facilities]
    do_search(@search_fields)
    add_optimizations
    @order_details = @order_details.paginate(:page => params[:page])
    
  end
  
  def facility_history
    
  end
  
  def do_search(search_params)
    Rails.logger.debug "search: #{search_params}"
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
  
  def remove_ugly_params
    if (params[:commit])
      params.delete(:commit)
      params.delete(:utf8)
      redirect_to params
      return false
    end
  end
  
  def get_my_accounts(allowed_accounts, search_accounts)
    search_accounts ||= []
    allowed_accounts = allowed_accounts.map{|a| a.id.to_s}
    denyed_accounts = search_accounts - allowed_accounts
    allowed_accounts - denyed_accounts
  end
  
  def add_optimizations
    # cut down on some n+1s
    @order_details = @order_details.includes(:order => :facility).includes(:account).includes(:product).includes(:order_status).includes(:reservation).includes(:order => :user)
  end
  # made this to handle nils and 'all' while keeping the above code cleaner
  def split_by_hyphen(str)
    return [] if str.nil? or str == "all"
    str.split("-")
  end
  
  # def load_filter_options
    # if (params[:account_id])
      # @account = session_user.accounts.find(params[:account_id])
    # else
      # @accounts = session_user.accounts
    # end 
#     
    # @facilities = Facility.active
  # end
  
  # def set_accounts(accounts)
    # @accounts = accounts
  # end
  
end
