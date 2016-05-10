class BulkEmailController < ApplicationController

  include CSVHelper

  admin_tab :all
  layout "two_column"

  before_filter { @active_tab = "admin_users" }
  before_filter :remove_ugly_params_and_redirect
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility
  before_filter { authorize! :send_bulk_emails, current_facility }

  before_filter :init_search_options

  def search
    if params[:search_type]
      searcher = BulkEmailSearcher.new(@search_fields)
      @users = searcher.do_search
      @order_details = searcher.order_details
    end

    respond_to do |format|
      format.html { @users = @users.paginate(page: params[:page]) if @users }
      format.csv do
        filename = "bulk_email_#{params[:search_type]}.csv"
        set_csv_headers(filename)
      end
    end
  end

  private

  def init_search_options
    @products = current_facility.products.active_plus_hidden.order("products.name").includes(:facility)
    @search_options = { products: @products }
    @search_fields = params.merge(facility_id: current_facility.id)
    @search_types = search_types
    @search_types.delete(:authorized_users) unless @products.exists?(requires_approval: true)
  end

  def search_types
    BulkEmailSearcher::SEARCH_TYPES.each_with_object({}) do |search_type, hash|
      hash[search_type] = I18n.t("bulk_email.search_type.#{search_type}")
    end
  end

end
