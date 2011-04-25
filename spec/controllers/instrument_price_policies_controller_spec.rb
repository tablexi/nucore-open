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
      assigns[:start_date].should_not be_nil
      assigns[:expire_date].should_not be_nil
      assigns[:price_policies].should be_is_a Array
      response.should be_success
      response.should render_template('instrument_price_policies/new.html.haml')
    end

  end


  context "edit" do

    before :each do
      @method=:get
      @action=:edit
      set_policy_date
      @params.merge!(:id => @price_policy.start_date.to_s)
    end

    it_should_allow_managers_only :success, 'to edit assigned effective price policy' do
      assigns[:start_date].should == Date.strptime(@params[:id], "%Y-%m-%d")
      assigns[:price_policies].should == [ @price_policy ]
      should render_template('edit')
    end


    it 'should not allow edit of assigned effective price policy' do
      @account  = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @director, :created_by => @director, :user_role => 'Owner']])
      @order    = @director.orders.create(Factory.attributes_for(:order, :created_by => @director.id))
      @order_detail = @order.order_details.create(Factory.attributes_for(:order_detail).update(:product_id => @instrument.id, :account_id => @account.id, :price_policy => @price_policy))
      UserPriceGroupMember.create!(:price_group => @price_group, :user => @director)
      maybe_grant_always_sign_in :director
      do_request
      assigns[:start_date].should == Date.strptime(@params[:id], "%Y-%m-%d")
      assigns[:price_policies].should be_empty
      should render_template '404.html.erb'
    end

  end


  context 'policy params' do

    before :each do
      @start_date=Time.zone.now+1.year
      @expire_date=PricePolicy.generate_expire_date(@start_date)

      @params.merge!({
        :interval => 5,
        :start_date => @start_date.to_s,
        :expire_date => @expire_date.to_s
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
        @params.merge!(:id => @price_policy.start_date.to_s)
      end

      it_should_allow_managers_only :redirect

    end


    context "destroy" do

      before :each do
        @method=:put
        @action=:update
        set_policy_date
        @params.merge!(:id => @price_policy.start_date.to_s)
      end

      it_should_allow_managers_only :redirect

    end

  end


  private

  def set_policy_date
    @price_policy.start_date=Time.zone.now+1.year
    @price_policy.expire_date=PricePolicy.generate_expire_date(@price_policy.start_date)

    unless @price_policy.valid?
      puts @price_policy.expire_date.to_s
    end

    assert @price_policy.save
  end

end
 