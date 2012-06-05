class BulkEmailController < ApplicationController
	include BulkEmailHelper
  
  admin_tab :all

  before_filter :authenticate_user!
	before_filter :check_acting_as
	before_filter :init_current_facility

	def new
		@search_fields = params.merge({})
		@products = current_facility.products
	end

	def create
		@search_fields = params.merge({})
    @products = current_facility.products
    @users = do_search(@search_fields)
	end

end