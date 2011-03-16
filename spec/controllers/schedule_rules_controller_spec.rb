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


  context 'create' do

    before :each do
      @method=:post
      @action=:create
      @params.merge!(
        :schedule_rule => Factory.attributes_for(:schedule_rule, :instrument => @instrument)
      )
    end

    it_should_allow_managers_only :redirect do
      should assign_to(:schedule_rule).with_kind_of ScheduleRule
      should set_the_flash
      assert_redirected_to facility_instrument_schedule_rules_url(@authable, @instrument)
    end

  end


  context 'needs schedule rule' do

    before :each do
      @rule=@instrument.schedule_rules.create(Factory.attributes_for(:schedule_rule))
      @params.merge!(:id => @rule.id)
    end


    context "edit" do

      before :each do
        @method=:get
        @action=:edit
      end

      it_should_allow_managers_only do
        assigns(:schedule_rule).should == @rule
        should render_template 'edit.html.haml'
      end

    end


    context 'update' do

      before :each do
        @method=:put
        @action=:update
        @params.merge!(
          :schedule_rule => Factory.attributes_for(:schedule_rule)
        )
      end

      it_should_allow_managers_only :redirect do
        assigns(:schedule_rule).should == @rule
        should set_the_flash
        assert_redirected_to facility_instrument_schedule_rules_url(@authable, @instrument)
      end

    end


    context 'destroy' do

      before :each do
        @method=:delete
        @action=:destroy
      end

      it_should_allow_managers_only :redirect do
        assigns(:schedule_rule).should == @rule
        should_be_destroyed @rule
        assert_redirected_to facility_instrument_schedule_rules_url(@authable, @instrument)
      end

    end

  end

end
 