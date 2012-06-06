module BulkEmailHelper
  def self.method_added(name)
    @@search_types ||= []
    if (name.to_s =~ /^search_(.*)$/)
      @@search_types << $1.to_sym
    end
  end

  def do_search(search_fields)
    return unless BulkEmailHelper::search_types.include? search_fields[:search_type]
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
    
  end

  def search_authorized_users(search_fields)
    result = User.joins(:product_users)
    # if we don't have any products, listed get them all for the current facility
    product_ids = search_fields[:products].presence || current_facility.products.map(&:id)
    result.where(:product_users => {:product_id => product_ids})
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
    order_details = order_details.joins(:order).where(:orders => {:facility_id => current_facility.id})

    reserve_start_date = parse_usa_date(search_fields[:reservation_start_date].to_s.gsub("-", "/"))
    reserve_end_date = parse_usa_date(search_fields[:reservation_end_date].to_s.gsub("-", "/")) 
    if reserve_start_date || reserve_end_date
      order_details = order_details.joins(:reservation) 
      order_details = order_details.action_in_date_range("reservations.reserve_start_at", reserve_start_date, reserve_end_date)
    end

    order_start_date = parse_usa_date(search_fields[:order_start_date].to_s.gsub("-", "/"))
    order_end_date = parse_usa_date(search_fields[:order_end_date].to_s.gsub("-", "/"))  
    order_details = order_details.action_in_date_range('orders.ordered_at', order_start_date, order_end_date)
    @order_details = order_details
    order_details
  end

  def find_users_from_order_details(order_details, user_id_field)
    user_ids = order_details.select("distinct(#{user_id_field}) as user_id").map(&:user_id).uniq
    User.find_all_by_id(user_ids)
  end

  def find_order_details_for_roles(search_fields, roles)
    find_order_details(search_fields).joins(:account => :account_users).where(:account_users => { :user_role => roles })
  end

end