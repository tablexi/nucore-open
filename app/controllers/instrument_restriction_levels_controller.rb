class InstrumentRestrictionLevelsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :init_current_facility
  load_and_authorize_resource :facility, :find_by => :url_name
  load_and_authorize_resource :instrument, :through => :facility, :find_by => :url_name
  load_and_authorize_resource :instrument_restriction_level, :through => :instrument
  
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
    if @instrument_restriction_level.update_attributes(params[:instrument_restriction_level])
      flash[:notice] = "#{InstrumentRestrictionLevel.model_name.human} was successfully updated"
      redirect_to facility_instrument_instrument_restriction_levels_path(@facility, @instrument)
    else
      render :action => :edit
    end
  end
  
  def create
    @instrument_restriction_level = @instrument.instrument_restriction_levels.new(params[:instrument_restriction_level])
    if @instrument_restriction_level.save
      flash[:notice] = "#{InstrumentRestrictionLevel.model_name.human} was successfully created"
      redirect_to facility_instrument_instrument_restriction_levels_path(@facility, @instrument)
    else
      render :action => :new
    end
  end
  
  def destroy
    if @instrument_restriction_level.destroy
      flash[:notice] = "#{InstrumentRestrictionLevel.model_name.human} was deleted"
      redirect_to facility_instrument_instrument_restriction_levels_path(@facility, @instrument)
    else
      flash[:error] = "There was an error deleting the #{InstrumentRestrictionLevel.model_name.human}"
      redirect_to edit_facility_instrument_instrument_restriction_levels_path(@facility, @instrument, @instrument_restriction_level)
    end
  end
end