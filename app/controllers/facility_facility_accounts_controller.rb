class FacilityFacilityAccountsController < ApplicationController

  admin_tab     :all
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_current_facility

  load_and_authorize_resource class: FacilityAccount

  layout "two_column"

  def initialize
    @active_tab = "admin_facility"
    super
  end

  # GET /facilities/:facility_id/facility_accounts(.:format)
  def index
    @accounts = current_facility.facility_accounts
  end

  # GET /facilities/:facility_id/facility_accounts/new(.:format)
  def new
    @facility_account = current_facility.facility_accounts.new(is_active: true, revenue_account: Settings.accounts.revenue_account_default)
  end

  # POST /facilities/:facility_id/facility_accounts(.:format)
  def create
    @facility_account = current_facility.facility_accounts.new(facility_account_params)
    @facility_account.created_by = session_user.id

    if @facility_account.save
      flash[:notice] = text("create.success", model: FacilityAccount.model_name.human)
      redirect_to facility_facility_accounts_path
    else
      render action: "new"
    end
  end

  # GET /facilities/:facility_id/facility_accounts/:id/edit(.:format)
  def edit
    @facility_account = current_facility.facility_accounts.find(params[:id])
  end

  # PUT /facilities/:facility_id/facility_accounts/:id(.:format)
  def update
    @facility_account = current_facility.facility_accounts.find(params[:id])

    if @facility_account.update_attributes(facility_account_params)
      flash[:notice] = text("update.success", model: FacilityAccount.model_name.human)
      redirect_to facility_facility_accounts_path
    else
      render action: "edit"
    end
  end

  private

  def facility_account_params
    params.require(:facility_account).permit(:revenue_account, :account_number, :is_active)
  end

end
