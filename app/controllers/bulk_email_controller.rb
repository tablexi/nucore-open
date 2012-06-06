class BulkEmailController < ApplicationController
	include BulkEmailHelper
  
  admin_tab :all

  before_filter :authenticate_user!
	before_filter :check_acting_as
	before_filter :init_current_facility
  before_filter { authorize! :send_bulk_emails, current_facility }
  before_filter :add_search_types

	def new
		@products = current_facility.products

    @search_fields = params.merge({})
	end

	def create
    @products = current_facility.products

    @search_fields = params.merge({})

    # default search type
    @search_fields[:search_type] ||= :customers
    
    @users = do_search(@search_fields).paginate(:page => params[:page])
	end

  private 
  def add_search_types
    @search_types = BulkEmailHelper.search_types_and_titles
  end

end