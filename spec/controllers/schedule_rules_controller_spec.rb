require 'spec_helper'; require 'controller_spec_helper'

describe ScheduleRulesController do
  integrate_views
  
  before(:all) { create_users }

  before(:each) do
    @authable         = Factory.create(:facility)
    @facility_account = @authable.facility_accounts.create(Factory.attributes_for(:facility_account))
    @price_group      = @authable.price_groups.create(Factory.attributes_for(:price_group))
    @instrument       = @authable.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
    @price_policy     = @instrument.instrument_price_policies.create(Factory.attributes_for(:instrument_price_policy).update(:price_group_id => @price_group.id))
    @price_policy.should be_valid
    @params={ :facility_id => @authable.url_name, :instrument_id => @instrument.url_name }
  end

  
  context "index" do

    before :each do
      @method=:get
      @action=:index
    end

    it_should_allow_operators_only do |user|
      assigns[:instrument].should == @instrument
      response.should be_success
      response.should render_template('schedule_rules/index.html.haml')

      if user.facility_staff?
        response.should_not have_tag('a', :text => 'Add Schedule Rule')
      else
        response.should have_tag('a', :text => 'Add Schedule Rule')
      end
    end

  end


  context "new" do

    before :each do
      @method=:get
      @action=:new
    end

    it_should_allow_managers_only do
      assigns[:instrument].should == @instrument
      response.should be_success
      response.should render_template('schedule_rules/new.html.haml')
    end

  end

end
 