class ScheduleRulesController < ApplicationController
  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility
  before_filter :init_instrument

  load_and_authorize_resource

  layout 'two_column'

  def initialize 
    @active_tab = 'admin_products'
    super
  end

  # GET /facilities/alias/instruments/3/schedule_rules.js?_=1279582221312&start=369205200&end=369810000
  def index
    @start_at       = Time.zone.at(params[:start].to_i)
    @end_at         = Time.zone.at(params[:end].to_i)
    @schedule_rules = @instrument.schedule_rules

    respond_to do |format|
      format.html # index.html.erb
      format.js { render :json => @schedule_rules.map(&:as_calendar_object).flatten }
    end
  end

  # GET /schedule_rules/new
  def new
    @schedule_rule  = ScheduleRule.new
    @schedule_rule.start_hour= 9
    @schedule_rule.start_min= 0
    @schedule_rule.end_hour= 17
    @schedule_rule.end_min= 0
  end

  # GET /schedule_rules/1/edit
  def edit
    @schedule_rule  = @instrument.schedule_rules.find(params[:id])
  end

  # POST /schedule_rules
  def create
    @schedule_rule  = @instrument.schedule_rules.new(params[:schedule_rule])

    respond_to do |format|
      if @schedule_rule.save
        flash[:notice] = 'Schedule Rule was successfully created.'
        format.html { redirect_to(facility_instrument_schedule_rules_path(current_facility, @instrument)) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /schedule_rules/1
  def update
    @schedule_rule  = ScheduleRule.find(params[:id])
    # TODO: 404 protection for non inst, facil rules
    
    # if there are no boxes checked, remove them all
    params[:schedule_rule][:product_access_group_ids] ||= []
    respond_to do |format|
      if @schedule_rule.update_attributes(params[:schedule_rule])
        flash[:notice] = 'Schedule Rule was successfully updated.'
        format.html { redirect_to(facility_instrument_schedule_rules_path(current_facility, @instrument)) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /schedule_rules/1
  def destroy
    @schedule_rule  = ScheduleRule.find(params[:id])
    # TODO: 404 on inappropriate schedule rules
    @schedule_rule.destroy

    respond_to do |format|
      format.html { redirect_to(facility_instrument_schedule_rules_path(current_facility, @instrument)) }
    end
  end

  def init_instrument
    @instrument     = current_facility.instruments.find_by_url_name!(params[:instrument_id])
  end
end
