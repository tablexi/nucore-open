module BulkEmail

  class BulkEmailController < ApplicationController

    include CSVHelper

    admin_tab :all
    layout "two_column"

    before_action { @active_tab = "admin_users" }
    before_action :authenticate_user!
    before_action :check_acting_as
    before_action :init_current_facility
    before_action :init_delivery_form, only: [:create, :deliver]
    before_action { authorize! :send_bulk_emails, current_facility }

    before_action :init_search_options, only: [:search]

    helper_method :bulk_email_cancel_path
    helper_method :datepicker_field_input
    helper_method :user_type_selected?

    def search
      @searcher = RecipientSearcher.new(@search_fields)
      @users = @searcher.do_search
    end

    def create
      @users = User.where_ids_in(params[:recipient_ids])

      respond_to do |format|
        format.csv do
          filename = "bulk_email_recipients.csv"
          set_csv_headers(filename)
        end

        format.html
      end
    end

    def deliver
      if @delivery_form.deliver_all
        flash[:notice] = text("bulk_email.delivery.success", count: @delivery_form.recipient_ids.count)
        redirect_to facility_bulk_email_path
      else
        flash[:error] = text("bulk_email.delivery.failure")
        @users = User.where_ids_in(@delivery_form.recipient_ids)
        render :create
      end
    end

    private

    def bulk_email_cancel_path
      if cancel_params.present?
        facility_bulk_email_path(cancel_params)
      else
        facility_bulk_email_path
      end
    end

    def cancel_params
      @cancel_params ||= params.slice(:start_date, :end_date, :bulk_email, :products)
    end

    def init_delivery_form
      @delivery_form = DeliveryForm.new(current_facility)
      @delivery_form.assign_attributes(params[:bulk_email_delivery_form])
    end

    def init_search_options
      @products = current_facility.products.active_plus_hidden.order("products.name").includes(:facility)
      @search_options = { products: @products }
      @search_fields = params.merge(facility_id: current_facility.id)
      @user_types = user_types
      @user_types.delete(:authorized_users) unless @products.exists?(requires_approval: true)
    end

    def datepicker_field_input(form, key)
      date = @search_fields[key].to_s.tr("-", "/")
      form.input(key, input_html: { value: date, class: :datepicker__data, name: key })
    end

    def user_types
      RecipientSearcher::USER_TYPES.each_with_object({}) do |user_type, hash|
        hash[user_type] = I18n.t("bulk_email.user_type.#{user_type}")
      end
    end

    def user_type_selected?(user_type)
      return false if params[:bulk_email].blank?
      params[:bulk_email][:user_types].include?(user_type.to_s)
    end

  end

end
