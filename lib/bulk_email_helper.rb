module BulkEmailHelper
  
  DEFAULT_SORT = [:last_name, :first_name]

  def self.method_added(name)
    @@search_types ||= []
    if (name.to_s =~ /^search_(.*)$/)
      @@search_types << $1.to_sym
    end
  end

  def do_search(search_fields)
    return unless BulkEmailHelper::search_types.include? search_fields[:search_type].to_sym
    @users = self.send(:"search_#{search_fields[:search_type]}", search_fields)
  end

  def search_customers(search_fields)
    order_details = find_order_details(search_fields).joins(:order => :user)
    find_users_from_order_details(order_details, "orders.user_id")
  end

  def search_account_owners(search_fields)
    order_details = find_order_details_for_roles(search_fields, [AccountUser::ACCOUNT_OWNER])
    find_users_from_order_details(order_details, 'account_users.user_id')
  end

  def search_customers_and_account_owners(search_fields)
    account_owner_order_details = find_order_details_for_roles(search_fields, [AccountUser::ACCOUNT_OWNER])
    account_owner_ids = find_user_ids_from_order_details(account_owner_order_details, 'account_users.user_id')

    customer_order_details = find_order_details(search_fields).joins(:order => :user)
    customer_ids = find_users_from_order_details(customer_order_details, "orders.user_id")

    find_users_from_ids((account_owner_ids + customer_ids).uniq)
  end

  def search_authorized_users(search_fields)
    result = User.joins(:product_users)
    # if we don't have any products, listed get them all for the current facility
    product_ids = search_fields[:products].presence || Facility.find(search_fields[:facility_id]).products.map(&:id)
    result.where(:product_users => {:product_id => product_ids}).reorder(*BulkEmailHelper::DEFAULT_SORT)
  end
  
  def self.search_types
    @@search_types
  end
  def self.search_types_and_titles
    Hash[@@search_types.map {|a| [a, I18n.t("bulk_email.search_type.#{a}")]}]
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

  def find_users_from_order_details(order_details, user_id_field, sort_fields = nil)
    user_ids = find_user_ids_from_order_details(order_details, user_id_field)
    find_users_from_ids(user_ids, sort_fields)
  end
  def find_user_ids_from_order_details(order_details, user_id_field)
    order_details.select("distinct(#{user_id_field}) as user_id").map(&:user_id).uniq
  end
  def find_users_from_ids(user_ids, sort_fields=nil)
    sort_fields = BulkEmailHelper::DEFAULT_SORT if sort_fields.blank?
    User.find_all_by_id(user_ids, :order => sort_fields)
  end

  def find_order_details_for_roles(search_fields, roles)
    find_order_details(search_fields).joins(:account => :account_users).where(:account_users => { :user_role => roles })
  end

end