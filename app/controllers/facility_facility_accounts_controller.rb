class FacilityFacilityAccountsController < ApplicationController
  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility

  load_and_authorize_resource :class => FacilityAccount

  layout 'two_column'
  
  def initialize
    @active_tab = 'admin_facility'
    super
  end
  
  # GET /facilities/:facility_id/facility_accounts(.:format)
  def index
    @accounts = current_facility.facility_accounts
  end
  
  # GET /facilities/:facility_id/facility_accounts/new(.:format)
  def new
    @facility_account = current_facility.facility_accounts.new(:is_active => true, :revenue_account => '50617')
  end

  # POST /facilities/:facility_id/facility_accounts(.:format)
  def create
    @facility_account = current_facility.facility_accounts.new(params[:facility_account])
    @facility_account.created_by = session_user.id

    if @facility_account.save
      flash[:notice] = 'Facility account was successfully created.'
      redirect_to facility_facility_accounts_path
    else
      render :action => "new"
    end
  end

  # GET /facilities/:facility_id/facility_accounts/:id/edit(.:format)
  def edit
    @facility_account = current_facility.facility_accounts.find(params[:id])
  end

  # PUT /facilities/:facility_id/facility_accounts/:id(.:format)
  def update
    @facility_account = current_facility.facility_accounts.find(params[:id])
    
    if @facility_account.update_attributes(params[:facility_account])
      flash[:notice] = 'Facility account was successfully updated.'
      redirect_to facility_facility_accounts_path
    else
      render :action => "edit"
    end
  end

end
