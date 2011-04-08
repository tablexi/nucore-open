class InstrumentPricePoliciesController < ApplicationController
  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility
  before_filter :init_instrument
  before_filter :init_instrument_price_policy, :except => :index

  load_and_authorize_resource

  layout 'two_column'
  
  def initialize
    @active_tab = 'admin_products'
    super
  end

  # GET /price_policies
  def index
    @current_price_policies = InstrumentPricePolicy.current(@instrument)
    @current_start_date = @current_price_policies.first ? @current_price_policies.first.start_date : nil

    @next_price_policies = InstrumentPricePolicy.next(@instrument)
    @next_start_date = @next_price_policies.first ? @next_price_policies.first.start_date : nil

    @next_dates = InstrumentPricePolicy.next_dates(@instrument)
  end

  # GET /price_policies/new
  def new
    @price_groups   = current_facility.price_groups
    @start_date     = (Date.today + (@instrument.price_policies.first.nil? ? 0 : 1)).strftime("%m/%d/%Y")
    @price_policies = @price_groups.map{ |pg| InstrumentPricePolicy.new({:price_group_id => pg.id, :instrument_id => @instrument.id, :start_date => @start_date, :usage_mins => 15 }) }
  end

  # GET /price_policies/1/edit
  def edit
    @price_groups = current_facility.price_groups
    @start_date   = Date.strptime((params[:start_date] || params[:id]), "%Y-%m-%d")
    raise ActiveRecord::RecordNotFound unless @start_date > Date.today
    @price_policies = InstrumentPricePolicy.for_date(@instrument, @start_date)

    raise ActiveRecord::RecordNotFound unless @price_policies.count > 0
  end

  # POST /price_policies
  def create
    @price_groups = current_facility.price_groups
    @interval     = params[:interval].to_i
    @start_date   = params[:start_date]
    @price_policies = @price_groups.map do |price_group|
      price_policy = InstrumentPricePolicy.new(params["instrument_price_policy#{price_group.id}"].reject {|k,v| k == 'restrict_purchase' })
      price_policy.price_group       = price_group
      price_policy.instrument        = @instrument
      price_policy.start_date        = Time.zone.parse(@start_date)
      price_policy.usage_mins        = @interval
      price_policy.reservation_mins  = @interval
      price_policy.overage_mins      = @interval
      price_policy.restrict_purchase = params["instrument_price_policy#{price_group.id}"]['restrict_purchase'] && params["instrument_price_policy#{price_group.id}"]['restrict_purchase'] == 'true' ? true : false
      price_policy
    end
    
    respond_to do |format|
      if ActiveRecord::Base.transaction do
          raise ActiveRecord::Rollback unless @price_policies.all? { |o| o.save }
          flash[:notice] = 'Price Rules were successfully created.'
          format.html { redirect_to facility_instrument_price_policies_url(current_facility, @instrument) }
        end
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /price_policies/1
  def update
    @price_groups   = current_facility.price_groups
    @start_date     = Date.strptime((params[:start_date] || params[:id]), "%Y-%m-%d")
    @price_policies = InstrumentPricePolicy.for_date(@instrument, @start_date)
    @price_policies.each { |price_policy|
      price_policy.attributes = params["instrument_price_policy#{price_policy.price_group.id}"].reject {|k,v| k == 'restrict_purchase' }
      price_policy.start_date = Time.zone.parse(params[:start_date])
      price_policy.restrict_purchase = params["instrument_price_policy#{price_policy.price_group.id}"]['restrict_purchase'] && params["instrument_price_policy#{price_policy.price_group.id}"]['restrict_purchase'] == 'true' ? true : false
    }

    respond_to do |format|
      if ActiveRecord::Base.transaction do
          raise ActiveRecord::Rollback unless @price_policies.all?(&:save)
          flash[:notice] = 'Price Rules were successfully updated'
          format.html { redirect_to facility_instrument_price_policies_url(current_facility, @instrument) }
        end
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /price_policies/1
  def destroy
    @price_groups   = current_facility.price_groups
    @start_date     = Date.strptime((params[:start_date] || params[:id]), "%Y-%m-%d")
    raise ActiveRecord::RecordNotFound unless @start_date > Date.today
    @price_policies = InstrumentPricePolicy.for_date(@instrument, @start_date)
    raise ActiveRecord::RecordNotFound unless @price_policies.count > 0
    
    respond_to do |format|
      if ActiveRecord::Base.transaction do
        raise ActiveRecord::Rollback unless @price_policies.all?(&:destroy)
        flash[:notice] = 'Price Rules were successfully removed'
        format.html { redirect_to facility_instrument_price_policies_url(current_facility, @instrument) }
        end
      else
        flash[:error] = 'An error was encountered while trying to remove the Price Rules'
        format.html { redirect_to facility_instrument_price_policies_url(current_facility, @instrument)  }
      end
    end
  end

  def init_instrument
    @instrument = current_facility.instruments.find_by_url_name!(params[:instrument_id])
  end

  #
  # Override CanCan's find -- it won't properly search by zoned date
  def init_instrument_price_policy
    @instrument_price_policy=InstrumentPricePolicy.find_by_start_date(Time.zone.parse(params[:start_date] || params[:id]))
  end

end
