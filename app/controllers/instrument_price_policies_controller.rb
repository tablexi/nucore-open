class InstrumentPricePoliciesController < PricePoliciesController

  # GET /price_policies/new
  def new
    super
    @price_policies.each do |pp|
      pp.usage_mins = 15
    end
  end

end
