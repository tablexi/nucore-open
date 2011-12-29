module TransactionSearch
  def self.included(base)    
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    def transaction_search(*actions)    
      self.before_filter :remove_ugly_params_and_redirect, :only => actions
      self.before_filter :populate_search_fields, :only => actions
    end
    def transaction_search2(*actions)
      actions.each do |action|
        class_eval do
          alias_method :"original_#{action}", "#{action}"
          define_method(action) do 
            @order_details = OrderDetail.joins(:order).joins(:product).ordered
            @order_details = @order_details.for_facility_url(params[:facility_id]) if params[:facility_id]          
            @order_details = @order_details.where(:account_id => params[:account_id]) if params[:account_id]
            
            send(:"original_#{action}")
            @facilities = Facility.find_by_sql(@order_details.joins(:order => :facility).select("distinct(facilities.id), facilities.name, facilities.abbreviation").to_sql)
            @accounts = Account.find_by_sql(@order_details.joins(:order => :account).select("distinct(accounts.id), accounts.description, accounts.account_number, accounts.type").to_sql)
            @products = Product.find_by_sql(@order_details.joins(:product).select("distinct(products.id), products.name, products.facility_id, products.type").to_sql)
            @account_owners = User.find_by_sql(@order_details.joins(:order => {:account => {:owner => :user} }).select("distinct(users.id), users.first_name, users.last_name").to_sql)
            @facility = @facilities.first
            @account = @accounts.first
            #@account_owners = []
            @search_fields = {}
            add_optimizations
          end
        end
      end
    end
    def use_date_field_for_search(field, *actions)
      self.prepend_before_filter(:only => actions) {|c| c.use_date_field field } 
    end
  end
  def populate_search_fields
    if params[:facility_id]
      @current_facility = @facility = Facility.find_by_url_name(params[:facility_id])
      raise ActiveRecord::RecordNotFound unless @facility
      @facilities = [@facility]
    else
      @facilities = Facility.active.order(:name)
    end
    
    if params[:account_id]
      @account = Account.find(params[:account_id])
      @accounts = [@account]
      @facilities = @account.facilities.order(:name)
      @facility = @facilities[0] if @facilities.size == 1
    else
      # only select a few fields. This speeds up the load when there get to be a lot of accounts
      @accounts = Account.for_facility(@facility).active.select("accounts.id, description, account_number, type")
      
      # sort accounts by description. may change to account number later
      @accounts = @accounts.order(:account_number, :description)
      
      # sort account owners by last name, first name
      @account_owners = @accounts.includes(:owner => :user).
                                map(&:owner_user).
                                uniq.
                                sort_by{|x| [x.last_name, x.first_name]}  
    end
    
    
    @products = Product.where("facility_id in (?)", @facilities.map(&:id)).order(:name) #:facility_id => @facility.id)
    
       
    @search_fields = params.merge({
      :accounts => get_allowed_accounts(@accounts, params[:accounts]),
      :facilities => @facilities
    })
    
    do_search(@search_fields)
    add_optimizations
  end
  def use_date_field(field)
    @date_field_to_use = field
  end
  def do_search(search_params)
    #Rails.logger.debug "search: #{search_params}"
    @order_details = @order_details || OrderDetail.joins(:order)
    @order_details = @order_details.ordered
    @order_details = @order_details.for_accounts(search_params[:accounts])
    @order_details = @order_details.for_products(search_params[:products])
    @order_details = @order_details.for_owners(search_params[:owners])
    start_date = parse_usa_date(search_params[:start_date].to_s.gsub("-", "/"))
    end_date = parse_usa_date(search_params[:end_date].to_s.gsub("-", "/"))  
    
    @order_details = @order_details.for_facilities(search_params[:facilities])
    @date_field_to_use ||= :fulfilled_at
    @order_details = @order_details.action_in_date_range(@date_field_to_use, start_date, end_date).
          order_by_desc_nulls_first(@date_field_to_use)    
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