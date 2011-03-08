require 'spec_helper'; require 'controller_spec_helper'

describe InstrumentPricePoliciesController do
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
      assigns[:current_price_policies].should == [@price_policy]
      response.should render_template('instrument_price_policies/index.html.haml')

      if user.facility_staff?
        response.should_not have_tag('a', :text => 'Add Pricing Rules')
      else
        response.should have_tag('a', :text => 'Add Pricing Rules')
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
      response.should render_template('instrument_price_policies/new.html.haml')
    end

  end


  context "edit" do

    before :each do
      @method=:get
      @action=:edit
      set_policy_date
      @params.merge!(:id => @price_policy.id, :start_date => @price_policy.start_date.to_s)
    end

    it_should_allow_managers_only

  end


  context 'policy params' do

    before :each do
      @params.merge!({
        :interval => 5,
        :start_date => (Time.zone.now+1.year).to_s
      })

      @authable.price_groups.each do |pg|
        @params.merge!("instrument_price_policy#{pg.id}".to_sym => Factory.attributes_for(:instrument_price_policy))
      end
    end


    context "create" do

      before :each do
        @method=:post
        @action=:create
      end

      it_should_allow_managers_only :redirect

    end


    context "update" do

      before :each do
        @method=:put
        @action=:update
        set_policy_date
        @params.merge!(:id => @price_policy.id)
      end

      it_should_allow_managers_only :redirect

    end


    context "destroy" do

      before :each do
        @method=:put
        @action=:update
        set_policy_date
        @params.merge!(:id => @price_policy.id)
      end

      it_should_allow_managers_only :redirect

    end

  end


  private

  def set_policy_date
    @price_policy.start_date=Time.zone.now+1.year
    assert @price_policy.save
  end

end
 