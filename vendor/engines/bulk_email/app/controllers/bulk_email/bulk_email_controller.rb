module BulkEmail

  class BulkEmailController < ApplicationController

    include CSVHelper

    admin_tab :all
    layout "two_column"

    before_action { @active_tab = "admin_users" }
    before_action :authenticate_user!
    before_action :check_acting_as
    before_action :init_current_facility
    before_action { authorize! :send_bulk_emails, current_facility }

    before_action :init_search_options

    def search
      searcher = BulkEmailSearcher.new(@search_fields)
      @users = searcher.do_search
      @order_details = searcher.order_details

      respond_to do |format|
        format.html { @users = @users.paginate(page: params[:page]) if @users }
        format.csv do
          filename = "bulk_email_#{params[:bulk_email][:user_types].join("-")}.csv"
          set_csv_headers(filename)
        end
      end
    end

    private

    def init_search_options
      @products = current_facility.products.active_plus_hidden.order("products.name").includes(:facility)
      @search_options = { products: @products }
      @search_fields = params.merge(facility_id: current_facility.id)
      @user_types = user_types
      @user_types.delete(:authorized_users) unless @products.exists?(requires_approval: true)
    end

    def user_types
      BulkEmailSearcher::USER_TYPES.each_with_object({}) do |user_type, hash|
        hash[user_type] = I18n.t("bulk_email.user_type.#{user_type}")
      end
    end

  end

end
