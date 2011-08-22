require 'spec_helper'; require 'controller_spec_helper'

describe InstrumentReportsController do
  include DateHelper

  render_views

  before(:all) { create_users }

  before(:each) do
    @authable=Factory.create(:facility)
    @params={
      :facility_id => @authable.url_name,
      :date_start => '07/08/2010',
      :date_end => '07/01/2011'
    }
  end


  context 'old reports' do

    before :each do
      @method=:get
    end


    context 'utilization' do

      before :each do
        @action=:utilization
      end

      it_should_allow_managers_only

    end

  end

end
