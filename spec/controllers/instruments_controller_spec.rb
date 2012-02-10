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

      it_should_allow_all(facility_operators) do
        assigns[:instrument].should == @instrument
        assert_redirected_to add_order_path(Order.all.last, :product_id => @instrument.id, :quantity => 1)
      end
    end
    
    context "restricted instrument" do
      before :each do
        @instrument.schedule_rules.create(Factory.attributes_for(:schedule_rule))
        @instrument.update_attributes(:requires_approval => true)
      end
      it "should show a notice if you're not approved" do
        sign_in @guest
        do_request
        assigns[:add_to_cart].should be_false
        flash[:notice].should_not be_nil
      end
      
      it "should not show a notice and show an add to cart" do
        @product_user = ProductUser.create(:product => @instrument, :user => @guest, :approved_by => @admin.id, :approved_at => Time.zone.now)
        sign_in @guest
        do_request
        flash.should be_empty
        assigns[:add_to_cart].should be_true
      end
      
      it "should allow an admin to allow it to add to cart" do
        sign_in @admin
        do_request
        flash.should_not be_empty
        assigns[:add_to_cart].should be_true
      end
    end
    
     context "hidden instrument" do
      before :each do
        @instrument.update_attributes(:is_hidden => true)
      end
      it "should throw a 404 if you're not an admin" do
        sign_in @guest
        do_request
        response.should_not be_success
        response.response_code.should == 404
      end
      it "should show the page if you're an admin" do
        # instruments have some complicated can_purchase rules requiring schedule rules
        # and price policies.
        Instrument.any_instance.stubs(:can_purchase?).returns(true)
        sign_in @admin
        do_request
        assigns[:instrument].should == @instrument
        assigns[:add_to_cart].should == true
        response.should be_redirect
      end
      it "should show the page if you're acting as a user" do
        Instrument.any_instance.stubs(:can_purchase?).returns(true)
        sign_in @admin
        switch_to @guest
        do_request
        assigns[:instrument].should == @instrument
        assigns[:add_to_cart].should == true
        response.should be_redirect
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
        :control_mechanism => 'manual',
        :instrument => Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id)
      )
    end

    it_should_allow_operators_only :redirect do
      assert_successful_creation { assigns(:instrument).relay.should be_nil }
    end

    context 'with relay' do

      before :each do
        @params[:control_mechanism]='relay'
        @params[:instrument].merge!({
          :relay_attributes => {
            :ip => '192.168.1.2',
            :port => 1234,
            :username => 'username',
            :password => 'password',
            :type => RelaySynaccessRevA.name,
            :instrument_id => -1 # nested attributes want something
          }
        })
      end

      it_should_allow :director, 'to create a relay' do
        assert_successful_creation do
          relay=assigns(:instrument).relay
          relay.should be_is_a Relay
          relay.ip.should == @params[:instrument][:relay_attributes][:ip]
          relay.port.should == @params[:instrument][:relay_attributes][:port]
          relay.username.should == @params[:instrument][:relay_attributes][:username]
          relay.password.should == @params[:instrument][:relay_attributes][:password]
          relay.type.should == @params[:instrument][:relay_attributes][:type]
        end
      end

      context 'dummy relay' do

        before :each do
          @params[:control_mechanism]='timer'
        end

        it_should_allow :director, 'to create a timer' do
          assert_successful_creation do
            relay=assigns(:instrument).relay
            relay.should be_is_a Relay
            relay.ip.should be_nil
            relay.port.should be_nil
            relay.username.should be_nil
            relay.password.should be_nil
            relay.type.should == RelayDummy.name
          end
        end

      end

    end


    context 'fail' do

      before :each do
        @params[:instrument].delete(:name)
      end

      it_should_allow :director, 'and fail when no name is given' do
        should assign_to(:instrument).with_kind_of Instrument
        assigns(:instrument).initial_order_status_id.should == OrderStatus.default_order_status.id
        should render_template 'new'
      end

    end


    def assert_successful_creation
      should assign_to(:instrument).with_kind_of Instrument
      assigns(:instrument).initial_order_status_id.should == OrderStatus.default_order_status.id
      yield
      should set_the_flash
      assert_redirected_to manage_facility_instrument_url(@authable, assigns(:instrument))
    end

  end


  context "update" do

    before :each do
      @method=:put
      @action=:update
      @params[:control_mechanism]='manual'
      @params.merge!(:instrument => @instrument.attributes)
    end

    context 'no relay' do
      before :each do
        RelaySynaccessRevA.create!(:instrument_id => @instrument.id)
      end

      it_should_allow_operators_only :redirect do
        assert_successful_update { assigns(:instrument).reload.relay.should be_nil }
      end
    end

    context 'with relay' do

      before :each do
        @params[:control_mechanism]='relay'
        @params[:instrument].merge!({
          :relay_attributes => {
            :ip => '192.168.1.2',
            :port => 1234,
            :username => 'username',
            :password => 'password',
            :type => RelaySynaccessRevA.name,
            :instrument_id => @instrument.id
          }
        })
      end

      it_should_allow :director, 'to create a relay' do
        assert_successful_update do
          relay=assigns(:instrument).relay
          relay.should be_is_a Relay
          relay.ip.should == @params[:instrument][:relay_attributes][:ip]
          relay.port.should == @params[:instrument][:relay_attributes][:port]
          relay.username.should == @params[:instrument][:relay_attributes][:username]
          relay.password.should == @params[:instrument][:relay_attributes][:password]
          relay.type.should == @params[:instrument][:relay_attributes][:type]
        end
      end

      context 'dummy relay' do

        before :each do
          @params[:control_mechanism]='timer'
        end

        it_should_allow :director, 'to create a timer' do
          assert_successful_update do
            relay=assigns(:instrument).relay
            relay.should be_is_a Relay
            relay.ip.should be_nil
            relay.port.should be_nil
            relay.username.should be_nil
            relay.password.should be_nil
            relay.type.should == RelayDummy.name
          end
        end

      end

    end

    def assert_successful_update
      assigns(:header_prefix).should == "Edit"
      assigns(:instrument).should == @instrument
      yield
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
      #assert_redirected_to manage_facility_instrument_url(@authable, assigns(:instrument))
      assert_redirected_to facility_instruments_url
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

