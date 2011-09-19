# TODO: extract the common logic between here and the other *PricePoliciesController into super class
class InstrumentPricePoliciesController < PricePoliciesController

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
    price_groups   = current_facility.price_groups
    start_date     = Date.today + (@instrument.price_policies.active.blank? ? 0 : 1)
    @expire_date    = PricePolicy.generate_expire_date(start_date).strftime("%m/%d/%Y")
    @start_date=start_date.strftime("%m/%d/%Y")
    @price_policies = price_groups.map{ |pg| InstrumentPricePolicy.new({:price_group_id => pg.id, :instrument_id => @instrument.id, :start_date => @start_date, :usage_mins => 15 }) }
  end

  # GET /price_policies/1/edit
  def edit
    @start_date   = start_date_from_params
    @price_policies = InstrumentPricePolicy.for_date(@instrument, @start_date)
    @price_policies.delete_if{|pp| pp.assigned_to_order? }
    raise ActiveRecord::RecordNotFound if @price_policies.blank?
    @expire_date=@price_policies.first.expire_date.to_date
  end

  # POST /price_policies
  def create
    price_groups = current_facility.price_groups
    @interval     = params[:interval].to_i
    @start_date   = params[:start_date]
    @expire_date   = params[:expire_date]
    price_groups.delete_if {|pg| !pg.can_purchase? @instrument }
    @price_policies = price_groups.map do |price_group|
      pp_param=params["instrument_price_policy#{price_group.id}"]
      price_policy = InstrumentPricePolicy.new(pp_param.reject {|k,v| k == 'restrict_purchase' })
      price_policy.price_group       = price_group
      price_policy.instrument        = @instrument
      price_policy.start_date        = parse_usa_date(@start_date)
      price_policy.expire_date       = parse_usa_date(@expire_date)
      price_policy.usage_mins        = @interval
      price_policy.reservation_mins  = @interval
      price_policy.overage_mins      = @interval
      price_policy.restrict_purchase = pp_param['restrict_purchase'] && pp_param['restrict_purchase'] == 'true' ? true : false
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
    @start_date     = start_date_from_params
    @expire_date    = params[:expire_date]
    @price_policies = InstrumentPricePolicy.for_date(@instrument, @start_date)
    @price_policies.each { |price_policy|
      pp_param=params["instrument_price_policy#{price_policy.price_group.id}"]
      next unless pp_param
      price_policy.attributes = pp_param.reject {|k,v| k == 'restrict_purchase' }
      price_policy.start_date = parse_usa_date(params[:start_date])
      price_policy.expire_date = parse_usa_date(@expire_date) unless @expire_date.blank?
      price_policy.restrict_purchase = pp_param['restrict_purchase'] && pp_param['restrict_purchase'] == 'true' ? true : false
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
    @start_date     = start_date_from_params

    unless @start_date > Date.today
      # force the user to really think about what they're doing, but tell them how to do it if they really want.
      flash[:notice]="Sorry, but you cannot remove an active price policy.<br/>If you really want to do so move the start date to the future and try again."
      return redirect_to facility_instrument_price_policies_path(current_facility, @instrument)
    end

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

end
