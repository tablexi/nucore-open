class BulkEmailController < ApplicationController
	include BulkEmailHelper
  
  admin_tab :all
  layout 'two_column'

  before_filter { @active_tab = 'admin_users' }
  

  before_filter :authenticate_user!
	before_filter :check_acting_as
	before_filter :init_current_facility
  before_filter { authorize! :send_bulk_emails, current_facility }
  
  before_filter :load_search_types
  before_filter :load_products

	def new
    @search_fields = params.merge({:facility_id => current_facility.id})
    render :search
	end

	def search
    @search_fields = params.merge({:facility_id => current_facility.id})

    # default search type
    @search_fields[:search_type] ||= :customers
    
    @users = do_search(@search_fields)

    respond_to do |format|
      format.html { @users = @users.paginate(:page => params[:page]) }
      format.csv
    end
	end

  private 
  def load_search_types
    @search_types = BulkEmailHelper.search_types_and_titles
  end
  def load_products
    @products = current_facility.products.active_plus_hidden.order(:name)
  end


end