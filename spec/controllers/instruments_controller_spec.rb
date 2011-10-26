require 'spec_helper'; require 'controller_spec_helper'

describe InstrumentsController do
  render_views

  it "should route" do
    { :get => "/facilities/alpha/instruments" }.should route_to(:controller => 'instruments', :action => 'index', :facility_id => 'alpha')
    { :get => "/facilities/alpha/instruments/1/manage" }.should route_to(:controller => 'instruments', :action => 'manage', :id => '1', :facility_id => 'alpha')
  end

  before(:all) { create_users }

  before(:each) do
    @authable         = Factory.create(:facility)
    @facility_account = @authable.facility_accounts.create(Factory.attributes_for(:facility_account))
    @instrument       = @authable.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
    @params={ :id => @instrument.url_name, :facility_id => @authable.url_name }
  end


  context "index" do

    before :each do
      @method=:get
      @action=:index
      @params.delete(:id)
    end

    it_should_allow_operators_only do |user|
      assigns[:instruments].should == [@instrument]
      response.should render_template('instruments/index')
    end

  end


  context "manage" do

    before :each do
      @method=:get
      @action=:manage
    end

    it_should_allow_operators_only do |user|
      response.should render_template('instruments/manage')
    end

  end


  context "show" do

    before :each do
      @method=:get
      @action=:show
    end

    it_should_allow :guest, 'but should not add to cart' do
      assigns[:instrument].should == @instrument
      assert_redirected_to facility_path(@authable)
    end

    context 'needs schedule rules' do
      before :each do
        @instrument.schedule_rules.create(Factory.attributes_for(:schedule_rule))
      end

      it "should require sign in" do
        do_request
        assigns[:instrument].should == @instrument
        session[:requested_params].should_not be_empty
        assert_redirected_to new_user_session_path
      end

      it_should_allow_all(facility_operators) do |op|
        assigns[:instrument].should == @instrument
        assert_redirected_to add_order_path(op.cart(op), :product_id => @instrument.id, :quantity => 1)
      end
    end
  end


  context "new" do

    before :each do
      @method=:get
      @action=:new
    end

    it_should_allow_operators_only do
      should assign_to(:instrument).with_kind_of Instrument
      assigns(:instrument).should be_new_record
      assigns(:instrument).facility.should == @authable
      should render_template 'new'
    end

  end


  context "edit" do

    before :each do
      @method=:get
      @action=:edit
    end

    it_should_allow_operators_only do
      should render_template 'edit'
    end

  end


  context "create" do

    before :each do
      @method=:post
      @action=:create
      @params.merge!(
        :instrument => Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id, :relay_port => 99)
      )
    end

    it_should_allow_operators_only :redirect do
      should assign_to(:instrument).with_kind_of Instrument
      assigns(:instrument).initial_order_status_id.should == OrderStatus.default_order_status.id
      should set_the_flash
      assert_redirected_to manage_facility_instrument_url(@authable, assigns(:instrument))
    end

  end


  context "update" do

    before :each do
      @method=:put
      @action=:update
      @params.merge!(
        :instrument => Factory.attributes_for(:item, :facility_account_id => @facility_account.id, :relay_port => 99)
      )
    end

    it_should_allow_operators_only :redirect do
      should assign_to(:instrument).with_kind_of Instrument
      should set_the_flash
      assert_redirected_to manage_facility_instrument_url(@authable, assigns(:instrument))
    end

  end


  context "destroy" do

    before :each do
      @method=:delete
      @action=:destroy
    end

    it_should_allow_operators_only :redirect do
      should assign_to(:instrument).with_kind_of Instrument
      assert_redirected_to manage_facility_instrument_url(@authable, assigns(:instrument))

      dead=false

      begin
        Instrument.find(assigns(:instrument).id)
      rescue
        dead=true
      end

      assert dead
    end

  end


  context 'instrument id' do

    before :each do
      @params.merge!(:instrument_id => @params[:id])
      @params.delete(:id)
    end


    context "schedule" do

      before :each do
        @method=:get
        @action=:schedule
      end

      it_should_allow_operators_only do
        should assign_to(:admin_reservations).with_kind_of Array
        should render_template 'schedule'
      end

    end


    context "agenda" do

      before :each do
        @method=:get
        @action=:agenda
      end

      it_should_allow_operators_only do
        should render_template 'agenda'
      end

    end


    context "status" do

      before :each do
        @method=:get
        @action=:instrument_status
      end

      it_should_allow_operators_only

    end


    context "switch" do

      before :each do
        @method=:get
        @action=:switch
        @params.merge!(:switch => 'on')
      end

      it_should_allow_operators_only

    end

  end

end

