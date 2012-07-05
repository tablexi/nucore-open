class BulkEmailController < ApplicationController
	include BulkEmailHelper
  include CSVHelper
  
  admin_tab :all
  layout 'two_column'

  before_filter { @active_tab = 'admin_users' }
  before_filter :remove_ugly_params_and_redirect
  before_filter :authenticate_user!
	before_filter :check_acting_as
	before_filter :init_current_facility
  before_filter { authorize! :send_bulk_emails, current_facility }
  
  before_filter :init_search_options

	def search
    @users = do_search(@search_fields) if params[:search_type]

    respond_to do |format|
      format.html { @users = @users.paginate(:page => params[:page]) if @users }
      format.csv do
        filename = "bulk_email_#{params[:search_type]}.csv"
        set_csv_headers(filename)
      end
    end
	end

  private 
  def init_search_options
    @search_fields = params.merge({:facility_id => current_facility.id})
    @products = current_facility.products.active_plus_hidden.order("products.name").includes(:facility)
    @search_types = BulkEmailHelper.search_types_and_titles
    @search_types.delete(:authorized_users) unless @products.exists?(:requires_approval => true)
  end

end