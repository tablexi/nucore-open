class FacilityAccountOrdersController < ApplicationController

  admin_tab :all

  before_filter :authenticate_user!
  before_filter { @active_tab = "admin_users" }

  layout "two_column"

  def index
    @account = Account.find(params[:account_id])
    authorize! :index, @account

    @order_details =
      @account
      .order_details
      .for_facility(current_facility)
      .purchased
      .order("orders.ordered_at DESC")
      .paginate(page: params[:page])
  end
end
