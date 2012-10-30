class FacilityOrdersImportController < ApplicationController

  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility

  authorize_resource :class => Order


  def initialize
    @active_tab = 'admin_orders'
    super
  end


  def new
  end


  def create
    render :action => 'show'
  end

end
