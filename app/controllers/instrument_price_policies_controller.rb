# TODO: extract the common logic between here and the other *PricePoliciesController into super class
class InstrumentPricePoliciesController < PricePoliciesController

  # GET /price_policies/new
  def new
    super
    @price_policies.each do |pp|
      pp.usage_mins = 15
    end
  end

end
