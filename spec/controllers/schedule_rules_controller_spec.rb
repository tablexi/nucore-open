require 'spec_helper'; require 'controller_spec_helper'

describe ScheduleRulesController do
  render_views

  before(:all) { create_users }

  before(:each) do
    @authable         = FactoryGirl.create(:facility)
    @facility_account = @authable.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
    @price_group      = @authable.price_groups.create(FactoryGirl.attributes_for(:price_group))
    @instrument       = FactoryGirl.create(:instrument, :facility => @authable, :facility_account_id => @facility_account.id)
    @price_policy     = @instrument.instrument_price_policies.create(FactoryGirl.attributes_for(:instrument_price_policy).update(:price_group_id => @price_group.id))
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
      response.should render_template('schedule_rules/index')
    end

  end


  context "new" do

    before :each do
      @method=:get
      @action=:new
    end

    it_should_allow_managers_and_senior_staff_only do
      assigns[:instrument].should == @instrument
      response.should be_success
      response.should render_template('schedule_rules/new')
    end

  end


  context 'create' do

    before :each do
      @method=:post
      @action=:create
      @params.merge!(
        :schedule_rule => FactoryGirl.attributes_for(:schedule_rule, :instrument_id => @instrument.id)
      )
    end

    it_should_allow_managers_and_senior_staff_only :redirect do
      expect(assigns(:schedule_rule)).to be_kind_of ScheduleRule
      should set_the_flash
      assert_redirected_to facility_instrument_schedule_rules_url(@authable, @instrument)
    end

    context 'with restriction levels' do
      before :each do
        @restriction_levels = []
        3.times do
          @restriction_levels << FactoryGirl.create(:product_access_group, :product_id => @instrument.id)
        end
        sign_in(@admin)
      end

      it "should come out with no restriction levels" do
        do_request
        assigns[:schedule_rule].product_access_groups.should be_empty
      end

      it "should store restriction_rules" do
        @params.deep_merge!(:schedule_rule => {:product_access_group_ids => [@restriction_levels[0].id, @restriction_levels[2].id]})
        do_request
        assigns[:schedule_rule].product_access_groups.should contain_all [@restriction_levels[0], @restriction_levels[2]]
        assigns[:schedule_rule].product_access_groups.size.should == 2
      end

    end

  end


  context 'needs schedule rule' do

    before :each do
      @rule=@instrument.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule))
      @params.merge!(:id => @rule.id)
    end


    context "edit" do

      before :each do
        @method=:get
        @action=:edit
      end

      it_should_allow_managers_and_senior_staff_only do
        assigns(:schedule_rule).should == @rule
        should render_template 'edit'
      end

    end


    context 'update' do

      before :each do
        @method=:put
        @action=:update
        @params.merge!(
          :schedule_rule => FactoryGirl.attributes_for(:schedule_rule)
        )
      end

      it_should_allow_managers_and_senior_staff_only :redirect do
        assigns(:schedule_rule).should == @rule
        should set_the_flash
        assert_redirected_to facility_instrument_schedule_rules_url(@authable, @instrument)
      end

      context 'restriction levels' do
        before :each do
          @restriction_levels = []
          3.times do
            @restriction_levels << FactoryGirl.create(:product_access_group, :product_id => @instrument.id)
          end
          sign_in(@admin)
        end

        it "should come out with no restriction levels" do
          do_request
          assigns[:schedule_rule].product_access_groups.should be_empty
        end

        it "should come out with no restriction levels if it had them before" do
          @rule.product_access_groups = @restriction_levels
          @rule.save!
          do_request
          assigns[:schedule_rule].product_access_groups.should be_empty
        end

        it "should store restriction_rules" do
          @params.deep_merge!(:schedule_rule => {:product_access_group_ids => [@restriction_levels[0].id, @restriction_levels[2].id]})
          do_request
          assigns[:schedule_rule].product_access_groups.should contain_all [@restriction_levels[0], @restriction_levels[2]]
          assigns[:schedule_rule].product_access_groups.size.should == 2
        end

      end

    end


    context 'destroy' do

      before :each do
        @method=:delete
        @action=:destroy
      end

      it_should_allow_managers_and_senior_staff_only :redirect do
        assigns(:schedule_rule).should == @rule
        should_be_destroyed @rule
        assert_redirected_to facility_instrument_schedule_rules_url(@authable, @instrument)
      end

    end

  end

end
