module BulkEmailHelper
  def do_search(search_fields)
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
    
    #only use this for testing (in specs)
    @order_details = order_details
    
    purchaser_ids = []
    account_ids = []
    authorized_user_ids = []

    if search_fields[:roles]
      account_ids = order_details.joins(:account => :account_users).where(:account_users => { :user_role => search_fields[:roles] }).select("distinct account_users.user_id")
    else
      purchaser_ids = order_details.select("distinct orders.user_id")
    end

    if search_fields[:authorized_user]
      authorized_user_ids = User.joins(:product_users).select("distinct users.id as user_id")
      authorized_user_ids = authorized_user_ids.where(:product_users => {:product_id => search_fields[:products]}) if search_fields[:products].present?
    end

    all_user_ids = (purchaser_ids + account_ids + authorized_user_ids).map(&:user_id).uniq

    users = User.find_all_by_id all_user_ids

  end


end