# TODO: extract the common logic between here and the other *PricePoliciesController into super class
class ServicePricePoliciesController < PricePoliciesController


  # PUT /price_policies/1
  def update
    @start_date = start_date_from_params
    @expire_date    = params[:expire_date]
    @price_policies = ServicePricePolicy.for_date(@service, @start_date)
    @price_policies.each { |price_policy|
      pp_param=params["service_price_policy#{price_policy.price_group.id}"]
      next unless pp_param
      price_policy.attributes = pp_param.reject {|k,v| k == 'restrict_purchase' }
      price_policy.start_date = Time.zone.parse(params[:start_date])
      price_policy.expire_date = Time.zone.parse(@expire_date) unless @expire_date.blank?
      price_policy.restrict_purchase = pp_param['restrict_purchase'] && pp_param['restrict_purchase'] == 'true' ? true : false
    }

    respond_to do |format|
      if ActiveRecord::Base.transaction do
          raise ActiveRecord::Rollback unless @price_policies.all?(&:save)
          flash[:notice] = 'Price Rules were successfully updated.'
          format.html { redirect_to facility_service_price_policies_url(current_facility, @service) }
        end
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /price_policies/2010-01-01
  def destroy
    @start_date     = start_date_from_params

    unless @start_date > Date.today
      # force the user to really think about what they're doing, but tell them how to do it if they really want.
      flash[:notice]="Sorry, but you cannot remove an active price policy.<br/>If you really want to do so move the start date to the future and try again."
      return redirect_to facility_service_price_policies_path(current_facility, @service)
    end

    @price_policies = ServicePricePolicy.for_date(@service, @start_date)
    raise ActiveRecord::RecordNotFound unless @price_policies.count > 0

    respond_to do |format|
      if ActiveRecord::Base.transaction do
        raise ActiveRecord::Rollback unless @price_policies.all?(&:destroy)
        flash[:notice] = 'Price Rules were successfully removed'
        format.html { redirect_to facility_service_price_policies_url(current_facility, @service) }
        end
      else
        flash[:error] = 'An error was encountered while trying to remove the Price Rules'
        format.html { redirect_to facility_service_price_policies_url(current_facility, @service)  }
      end
    end
  end

end
