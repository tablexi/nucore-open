class FacilityAccountsReconciliationController < ApplicationController

  admin_tab :all
  layout "two_column"

  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility
  before_filter :check_billing_access
  before_filter :set_billing_navigation
  before_filter { @accounts = account_class.need_reconciling(current_facility) }

  def index
    if @accounts.none?
      # do nothing, just render
    elsif selected_account
      @unreconciled_details = unreconciled_details
      @balance = selected_account.unreconciled_total(current_facility, @unreconciled_details)
    else
      redirect_to([account_route, :facility_accounts])
    end
  end

  def update
    update_account
    redirect_to([account_route, :facility_accounts])
  end

  private

  def set_billing_navigation
    @subnav = "billing_nav"
    @active_tab = "admin_billing"
  end

  def account_route
    Account.config.account_type_to_route(params[:account_type])
  end
  helper_method :account_route

  def selected_account
    @selected_account ||= if params[:selected_account].present?
                            @accounts.find_by_id(params[:selected_account])
                          else
                            @accounts.first
    end
  end

  def account_class
    # This is coming in from the router, not the user, so it should be safe
    params[:account_type].constantize
  end
  helper_method :account_class

  def unreconciled_details
    OrderDetail
      .account_unreconciled(current_facility, selected_account)
      .order(%w(
               order_details.account_id
               order_details.statement_id
               order_details.order_id
               order_details.id))
      .paginate(page: params[:page])
  end

  def update_account
    @error_fields = {}
    update_details = unreconciled_details.readonly(false).find(params[:order_detail].keys)

    OrderDetail.transaction do
      count = 0
      update_details.each do |od|
        od_params = params[:order_detail][od.id.to_s]
        od.reconciled_note = od_params[:notes]

        begin
          if od_params[:reconciled] == "1"
            od.change_status!(OrderStatus.reconciled.first)
            count += 1
          else
            od.save!
          end
        rescue => e
          @error_fields = { od.id => od.errors.collect { |field, _error| field } }
          errors = od.errors.full_messages
          errors = [$ERROR_INFO.message] if errors.empty?
          flash.now[:error] = (["There was an error processing the #{account_class.name.underscore.humanize.downcase} payments"] + errors).join("<br />")
          raise ActiveRecord::Rollback
        end
      end

      flash[:notice] = "#{count} payment#{count == 1 ? '' : 's'} successfully reconciled" if count > 0
    end
  end

end
