require 'spec_helper'
require 'controller_spec_helper'
require 'price_policies_controller_shared_examples'

describe InstrumentPricePoliciesController do
  render_views
  
  before(:all) { create_users }

  it_should_behave_like PricePoliciesController, :instrument

end
 