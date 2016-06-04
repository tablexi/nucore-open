class FacilityAccountsReconciliationController < ApplicationController

  include DateHelper

  admin_tab :all
  layout "two_column"

  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_current_facility
  before_action :check_billing_access
  before_action :set_billing_navigation
  before_action { @accounts = account_class.need_reconciling(current_facility) }

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
    reconciled_at = parse_usa_date(params[:reconciled_at])
    reconciler = OrderDetails::Reconciler.new(unreconciled_details, params[:order_detail], reconciled_at)

    if reconciler.reconcile_all > 0
      count = reconciler.count
      flash[:notice] = "#{count} payment#{count == 1 ? '' : 's'} successfully reconciled" if count > 0
    else
      flash[:error] = reconciler.full_errors.join("<br />").html_safe
    end
  end

end
