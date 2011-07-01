require 'spec_helper'; require 'controller_spec_helper'

describe ReportsController do
  render_views

  before(:all) { create_users }

  before(:each) do
    @authable=Factory.create(:facility)
    @params={ :facility_id => @authable.url_name }
  end


  context 'instrument_utilization' do

    before :each do
      @method=:get
      @action=:instrument_utilization
    end

    it_should_allow_managers_only

  end


  context 'product_order_summary' do

    before :each do
      @method=:get
      @action=:product_order_summary
    end

    it_should_allow_managers_only

  end

end
