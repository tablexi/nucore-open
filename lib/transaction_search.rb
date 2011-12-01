module TransactionSearch
  def self.included(base)
    base.before_filter :find_with_facility, :only => [:search, :index]
    base.before_filter :remove_ugly_params, :only => [:search, :index]
  end
   
  def find_with_facility
    @current_facility = @facility = Facility.find_by_url_name(params[:facility_id])
    raise ActiveRecord::RecordNotFound unless @facility
    @facilities = [@facility]
    # only select a few fields. This speeds up the load when there get to be a lot of accounts
    @accounts = Account.for_facility(@facility).select("id, description, account_number, type")
    
    @search_fields = params.merge({
      :accounts => get_allowed_accounts(@accounts, params[:accounts]),
      :facilities => @facilities
    })
    
    do_search(@search_fields)
    add_optimizations
  end
      
  def do_search(search_params)
    Rails.logger.debug "search: #{search_params}"
    @order_details = OrderDetail.joins(:order).ordered
    @order_details = @order_details.for_accounts(search_params[:accounts])
    
    start_date = parse_usa_date(search_params[:start_date].to_s.gsub("-", "/"))
    end_date = parse_usa_date(search_params[:end_date].to_s.gsub("-", "/"))  
    
    @order_details = @order_details.for_facilities(search_params[:facilities]).
      fulfilled_in_date_range(start_date, end_date).
      order_by_desc_nulls_first(:fulfilled_at)    
  end
  
  def remove_ugly_params
    if (params[:commit])
      params.delete(:commit)
      params.delete(:utf8)
      redirect_to params
      return false
    end
  end
    
  def get_allowed_accounts(allowed_accounts, search_accounts)
    search_accounts ||= []
    allowed_accounts = allowed_accounts.map{|a| a.id.to_s}
    denyed_accounts = search_accounts - allowed_accounts
    search_accounts - denyed_accounts
  end
  
  def add_optimizations
    # cut down on some n+1s
    @order_details = @order_details.
        includes(:order => :facility).
        includes(:account).
        includes(:product).
        includes(:order_status).
        includes(:reservation).
        includes(:order => :user).
        includes(:price_policy)
        
  end
  
  
end