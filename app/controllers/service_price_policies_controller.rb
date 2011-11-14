# TODO: extract the common logic between here and the other *PricePoliciesController into super class
class ServicePricePoliciesController < PricePoliciesController


  

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
