module BulkEmailHelper
  
  DEFAULT_SORT = [:last_name, :first_name]
  SEARCH_TYPES = [:customers, :account_owners, :customers_and_account_owners, :authorized_users]

  def do_search(search_fields)
    return unless BulkEmailHelper::search_types.include? search_fields[:search_type].to_sym
    @users = self.send(:"search_#{search_fields[:search_type]}", search_fields)
  end

  def search_customers(search_fields)
    order_details = find_order_details(search_fields).joins(:order => :user)
    User.find_by_sql(order_details.select("distinct(users.id), users.*").
                                          reorder("users.last_name, users.first_name").to_sql)
  end

  def search_account_owners(search_fields)
    order_details = find_order_details_for_roles(search_fields, [AccountUser::ACCOUNT_OWNER])
    User.find_by_sql(order_details.joins(:account => {:account_users => :user}).
                                   select("distinct(users.id), users.*").
                                   reorder("users.last_name, users.first_name").to_sql)
  end

  def search_customers_and_account_owners(search_fields)
    customers = search_customers(search_fields)
    account_owners = search_account_owners(search_fields)
    (customers + account_owners).uniq.sort {|x,y| x.last_name <=> y.last_name }
  end

  def search_authorized_users(search_fields)
    result = User.joins(:product_users)
    # if we don't have any products, listed get them all for the current facility
    product_ids = search_fields[:products].presence || Facility.find(search_fields[:facility_id]).products.map(&:id)
    result.where(:product_users => {:product_id => product_ids}).reorder(*BulkEmailHelper::DEFAULT_SORT)
  end
  
  def self.search_types
    SEARCH_TYPES
  end
  def self.search_types_and_titles
    # This can be changed to just Hash once we no longer have to support ruby 1.8.7
    ActiveSupport::OrderedHash[self.search_types.map {|a| [a, I18n.t("bulk_email.search_type.#{a}")]}]
  end

  private

  def find_order_details(search_fields)
    order_details = OrderDetail.for_products(search_fields[:products])
    order_details = order_details.joins(:order).where(:orders => {:facility_id => search_fields[:facility_id]})

    start_date = parse_usa_date(search_fields[:start_date].to_s.to_s.gsub("-", "/")) if search_fields[:start_date]
    end_date = parse_usa_date(search_fields[:end_date].to_s.to_s.gsub("-", "/")) if search_fields[:end_date]
    order_details = order_details.ordered_or_reserved_in_range(start_date, end_date)
    
    @order_details = order_details
    order_details
  end

  def find_order_details_for_roles(search_fields, roles)
    find_order_details(search_fields).joins(:account => :account_users).where(:account_users => { :user_role => roles })
  end

end