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


  context 'instrument' do

    before :each do
      @method=:get
      @action=:instrument
    end

    it_should_allow_managers_only

  end


  context 'account' do

    before :each do
      @method=:get
      @action=:account
    end

    it_should_allow_managers_only

  end


  context 'account_owner' do

    before :each do
      @method=:get
      @action=:account_owner
    end

    it_should_allow_managers_only

  end


  context 'purchaser' do

    before :each do
      @method=:get
      @action=:purchaser
    end

    it_should_allow_managers_only

  end

end
