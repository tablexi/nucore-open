class ProductAccessGroupsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :init_current_facility

  load_and_authorize_resource :facility, :find_by => :url_name
  load_and_authorize_resource :instrument, :through => :facility, :find_by => :url_name
  load_and_authorize_resource :product_access_group, :through => :instrument

  layout 'two_column'
  
  def initialize
    @active_tab = 'admin_products'
    super
  end
  
  def index
  end
  
  def edit
  end
  
  def new
  end
  
  def update
    if @product_access_group.update_attributes(params[:product_access_group])
      flash[:notice] = "#{ProductAccessGroup.model_name.human} was successfully updated"
      redirect_to facility_instrument_product_access_groups_path(@facility, @instrument)
    else
      render :action => :edit
    end
  end
  
  def create
    @product_access_group = @instrument.product_access_groups.new(params[:product_access_group])
    if @product_access_group.save
      flash[:notice] = "#{ProductAccessGroup.model_name.human} was successfully created"
      redirect_to facility_instrument_product_access_groups_path(@facility, @instrument)
    else
      render :action => :new
    end
  end
  
  def destroy
    if @product_access_group.destroy
      flash[:notice] = "#{ProductAccessGroup.model_name.human} was deleted"
      redirect_to facility_instrument_product_access_groups_path(@facility, @instrument)
    else
      flash[:error] = "There was an error deleting the #{ProductAccessGroup.model_name.human}"
      redirect_to edit_facility_instrument_product_access_groups_path(@facility, @instrument, @product_access_group)
    end
  end

end