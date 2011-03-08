require 'spec_helper'; require 'controller_spec_helper'

describe InstrumentsController do
  integrate_views

  it "should route" do
    params_from(:get, "/facilities/alpha/instruments").should == {:controller => 'instruments', :action => 'index', :facility_id => 'alpha'}
    params_from(:get, "/facilities/alpha/instruments/1/manage").should == {:controller => 'instruments', :action => 'manage', :id => '1', :facility_id => 'alpha'}
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
      response.should render_template('instruments/index.html.haml')

      unless user.facility_staff?
        response.should have_tag('a', :text => 'Add Instrument')
        response.should have_tag('a', :text => @instrument.name)
      else
        # should not have 'add facility' link
        response.should_not have_tag('a', :text => 'Add Instrument')
        # should not have 'authorize user' link
        response.should_not have_tag('a', :text => 'Authorize User')
        # should have 'manage instrument' link
        response.should have_tag('a', :text => @instrument.name)
      end
    end

  end


  context "manage" do

    before :each do
      @method=:get
      @action=:manage
    end

    it_should_allow_operators_only do |user|
      response.should render_template('instruments/manage.html.haml')

      unless user.facility_staff?
        response.should have_tag('a', :text => 'Edit')
      else
        response.should_not have_tag('a', :text => 'Edit')
      end
    end

  end


  context "show" do

    before :each do
      @method=:get
      @action=:show
      @block=Proc.new do
        assigns[:instrument].should == @instrument
        response.should be_success
        response.should render_template('instruments/show.html.haml')
      end
    end

    it "should all public access" do
      do_request
      @block.call
    end

    it_should_allow(:guest) { @block.call }

    it_should_allow_all(facility_operators) { @block.call }

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
      should render_template 'new.html.haml'
    end

  end


  context "edit" do

    before :each do
      @method=:get
      @action=:edit
    end

    it_should_allow_operators_only do
      should render_template 'edit.html.haml'
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
        should render_template 'schedule.html.haml'
      end

    end


    context "agenda" do

      before :each do
        @method=:get
        @action=:agenda
      end

      it_should_allow_operators_only do
        should render_template 'agenda.html.haml'
      end

    end


    context "status" do

      before :each do
        @method=:get
        @action=:status
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

