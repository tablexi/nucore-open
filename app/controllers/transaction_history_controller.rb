class TransactionHistoryController < ApplicationController
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
    if (params[:search_fields])
      extracted_params = extract_parameters(params[:search_fields])
      @search_fields = extracted_params
      do_search(extracted_params)
    elsif (params[:commit])
      puts "params: #{params}"
      combined_params = combine_parameters(params)
      puts "combined: #{combined_params}"
      redirect_to transaction_history_search_path(combined_params)
      return
    else
      do_search(params)
      @search_fields = {}
    end
    @order_details = @order_details.paginate(:page => params[:page])
    render :action => "index"      
  end
  
  def do_search(search_params)
    start_date = parse_usa_date(search_params[:start_date])
    end_date = parse_usa_date(search_params[:end_date])   
    @order_details = OrderDetail.ordered
    if (@account)
      @order_details = @order_details.for_accounts([@account.id])
    else
      !@order_details = @order_details.for_accounts(search_params[:accounts])
    end
    @order_details = @order_details.joins(:order).for_facilities(search_params[:facilities]).
      in_date_range(start_date, end_date).
      order("orders.ordered_at DESC")
  end
   
  def extract_parameters(query)
    search_params = {}
    # accounts/facilities/start_date/end_date
    # 12-13/facility1-facility2/2011-01-01/2012-01-01/
    regex = /^(?:([0-9-]+)(?:\/))?([\w-]+|all)\/(all|[0-9]{2}-[0-9]{2}-[0-9]{4})\/(all|[0-9]{2}-[0-9]{2}-[0-9]{4})$/
    results = regex.match(query).to_a
    raise ActionController::RoutingError.new("Invalid Parameters") if results.empty?

    results.shift # first item is the full match, which we don't need
    search_params[:accounts] = split_by_hyphen(results.shift) 
    
    facility_ids = Facility.ids_from_urls(split_by_hyphen(results.shift))
    if facility_ids.any?
      search_params[:facilities] = facility_ids
    end
    sdate = results.shift # make sure it shifts off, regardless of whether we return it
    search_params[:start_date] = sdate unless sdate == "all"
    edate = results.shift
    search_params[:end_date] = edate unless edate == "all"
    return search_params
  end
  
  def combine_parameters(search_parameters)
    sections = []
    sections << search_parameters[:accounts].join("-") if (search_parameters[:accounts])
    # facility
    if search_parameters[:facilities].nil? or search_parameters[:facilities].empty?
      sections << "all"
    else
      urls = Facility.urls_from_ids(search_parameters[:facilities])
      sections << urls.sort.join("-")
    end
    sections << (search_parameters[:start_date].presence || "all").gsub("/","-")
    sections << (search_parameters[:end_date].presence || "all").gsub("/","-")
    return sections.join("/")
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
      @accounts = Account.active
    end 
    
    @facilities = Facility.active
  end
end
