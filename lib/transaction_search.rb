module TransactionSearch
  def self.included(base)    
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    def transaction_search(*actions)
      self.before_filter :remove_ugly_params_and_redirect, :only => actions
    end
    
    # If a method is tagged with _with_search at the end, then define the normal controller
    # action to be wrapped in the search.
    # e.g. index_with_search will define #index, which will init_order_details before passing
    # control to the controller method. Then it will further filter @order_details after the controller
    # method has run 
    def method_added(name)
      @@methods_with_remove_ugly_filter ||= []
      if (name.to_s =~ /(.*)_with_search$/)
        @@methods_with_remove_ugly_filter << $1
        self.before_filter :remove_ugly_params_and_redirect, :only => @@methods_with_remove_ugly_filter
        define_method($1) do 
          init_order_details
          send(:"#{$&}")
          load_search_options
          @empty_orders = @order_details.empty?
          @search_fields = params.merge({})
          do_search(@search_fields)
          add_optimizations
          @order_details = @order_details_sort ? @order_details.reorder(@order_details_sort) : @order_details.order_by_desc_nulls_first(@date_field_to_use)
          @order_details = @order_details.paginate(:page => params[:page]) if @paginate_order_details
          render :layout => @layout if @layout
        end
      end
    end
  end
  
  def init_order_details
    @order_details = OrderDetail.joins(:order).joins(:product).ordered

    if current_facility
      @order_details = @order_details.for_facility(current_facility)
    end

    @order_details = @order_details.where(:account_id => @account.id) if @account
  end
    
  # Find all the unique search options based on @order_details. This needs to happen before do_search so these
  # variables have the full non-searched section of values
  def load_search_options
    @facilities = Facility.find_by_sql(@order_details.joins(:order => :facility).
                                                      select("distinct(facilities.id), facilities.name, facilities.abbreviation").
                                                      reorder("facilities.name").to_sql)

    @accounts = Account.find_by_sql(@order_details.joins(:order => :account).
                                                   select("distinct(accounts.id), accounts.description, accounts.account_number, accounts.type").
                                                   reorder("accounts.account_number, accounts.description").to_sql)
    @products = Product.find_by_sql(@order_details.joins(:product).
                                                   select("distinct(products.id), products.name, products.facility_id, products.type").
                                                   reorder("products.name").to_sql)
    @account_owners = User.find_by_sql(@order_details.joins(:order => {:account => {:owner => :user} }).
                                                      select("distinct(users.id), users.first_name, users.last_name").
                                                      reorder("users.last_name, users.first_name").to_sql)
  end
      
  def paginate_order_details
    @paginate_order_details = true
  end
  
  def order_details_sort(field)
    @order_details_sort = field
  end
  
  private
  
  def do_search(search_params)
    #Rails.logger.debug "search: #{search_params}"
    @order_details = @order_details || OrderDetail.joins(:order).ordered
    @order_details = @order_details.for_accounts(search_params[:accounts])
    @order_details = @order_details.for_products(search_params[:products])
    @order_details = @order_details.for_owners(search_params[:account_owners])
    start_date = parse_usa_date(search_params[:start_date].to_s.gsub("-", "/"))
    end_date = parse_usa_date(search_params[:end_date].to_s.gsub("-", "/"))  
    
    @order_details = @order_details.for_facilities(search_params[:facilities])
    @date_field_to_use ||= :fulfilled_at
    @order_details = @order_details.action_in_date_range(@date_field_to_use, start_date, end_date)
  end  

  def remove_ugly_params_and_redirect
    if (params[:commit] && request.get?)
      remove_ugly_params
      redirect_to params
      return false
    end
  end
  def remove_ugly_params
    params.delete(:commit)
    params.delete(:utf8)
    params.delete(:authenticity_token)
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
