class BulkEmailController < ApplicationController
	before_filter :authenticate_user!
	before_filter :check_acting_as
	before_filter :init_current_facility

	def new
		@search_fields = params.merge({})
		@products = current_facility.products
	end

	def create
		@users = User.joins(:orders).joins(:order_details)
		@users = @users.joins(:products)
		
		order_details = OrderDetail.for_products(params[:products])
		logger.debug(order_details.to_sql)
		logger.debug(order_details)
		reserve_start_date = parse_usa_date(params[:reservation_start_date].to_s.gsub("-", "/"))
    	reserve_end_date = parse_usa_date(params[:reservation_end_date].to_s.gsub("-", "/")) 
    	order_details = order_details.action_in_date_range("reservations.reserve_start_at", reserve_start_date, reserve_end_date)
    	logger.debug("With reservations: #{order_details.to_sql}")

		order_start_date = parse_usa_date(params[:order_start_date].to_s.gsub("-", "/"))
    	order_end_date = parse_usa_date(params[:order_end_date].to_s.gsub("-", "/"))  
    	order_details = order_details.action_in_date_range('orders.ordered_at', order_start_date, order_end_date)
    	logger.debug(order_details.to_sql)

    	@users = @users.joins(:order_details => :reservation)
    	
    	@users = @users.merge(order_details)
		@users = @users.group('users.id')

		@search_fields = params.merge({})
		@products = current_facility.products
	end

end