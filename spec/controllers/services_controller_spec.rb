require 'spec_helper'; require 'controller_spec_helper'

describe ServicesController do
  render_views

  it "should route" do
    { :get => "/facilities/alpha/services" }.should route_to(:controller => 'services', :action => 'index', :facility_id => 'alpha')
    { :get => "/facilities/alpha/services/1/manage" }.should route_to(:controller => 'services', :action => 'manage', :id => '1', :facility_id => 'alpha')
  end

  before(:all) { create_users }

  before(:each) do
    @authable         = Factory.create(:facility)
    @facility_account = @authable.facility_accounts.create(Factory.attributes_for(:facility_account))
    @service          = @authable.services.create(Factory.attributes_for(:service, :facility_account_id => @facility_account.id))
    @params={ :facility_id => @authable.url_name }
  end


  context "index" do

    before :each do
      @method=:get
      @action=:index
    end

    it_should_allow_operators_only do
      assigns[:services].should == [@service]
      response.should be_success
      response.should render_template('services/index')
    end

  end


  context "show" do

    before :each do
      @method=:get
      @action=:show
      @params.merge!(:id => @service.url_name)
    end

    it "should allow public access" do
      do_request
      assigns[:service].should == @service
      response.should be_success
      response.should render_template('services/show')
    end
  
    it_should_allow_all facility_users do
      assigns[:service].should == @service
      response.should be_success
      response.should render_template('services/show')
    end
    
    context "restricted service" do
      before :each do
        @service.update_attributes(:requires_approval => true)
      end
      it "should show a notice if you're not approved" do
        sign_in @guest
        do_request
        assigns[:add_to_cart].should be_false
        flash[:notice].should_not be_nil
      end
      
      it "should not show a notice and show an add to cart" do
        @product_user = ProductUser.create(:product => @service, :user => @guest, :approved_by => @admin.id, :approved_at => Time.zone.now)
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
    
    context "hidden service" do
      before :each do
        @service.update_attributes(:is_hidden => true)
      end
      it "should throw a 404 if you're not an admin" do
        sign_in @guest
        do_request
        response.should_not be_success
        response.response_code.should == 404
      end
      it "should show the page if you're an admin" do
        sign_in @admin
        do_request
        response.should be_success
        assigns[:service].should == @service
      end
      it "should show the page if you're acting as a user" do
        ServicesController.any_instance.stubs(:acting_user).returns(@guest)
        ServicesController.any_instance.stubs(:acting_as?).returns(true)
        sign_in @admin
        do_request
        response.should be_success
        assigns[:service].should == @service
      end
    end
  end


  context 'new' do

    before :each do
      @method=:get
      @action=:new
    end

    it_should_allow_managers_only do
      should assign_to(:service).with_kind_of Service
      assigns(:service).facility.should == @authable
    end

  end


  context 'edit' do

    before :each do
      @method=:get
      @action=:edit
      @params.merge!(:id => @service.url_name)
    end

    it_should_allow_managers_only do
      should render_template 'edit'
    end

  end


  context 'create' do

    before :each do
      @method=:post
      @action=:create
      @params.merge!(:service => Factory.attributes_for(:service, :facility_account_id => @facility_account.id))
    end

    it_should_allow_managers_only :redirect do
      should assign_to(:service).with_kind_of Service
      assigns(:service).facility.should == @authable
      should set_the_flash
      assert_redirected_to [:manage, @authable, assigns(:service)]
    end

  end


  context 'update' do

    before :each do
      @method=:put
      @action=:update
      @params.merge!(:id => @service.url_name, :service => Factory.attributes_for(:service, :facility_account_id => @facility_account.id))
    end

    it_should_allow_managers_only :redirect do
      should assign_to(:service).with_kind_of Service
      should set_the_flash
      assert_redirected_to manage_facility_service_url(@authable, assigns(:service))
    end

  end


  context 'destroy' do

    before :each do
      @method=:delete
      @action=:destroy
      @params.merge!(:id => @service.url_name)
    end

    it_should_allow_managers_only :redirect do
      assigns(:service).should == @service
      should_be_destroyed @service
      assert_redirected_to facility_services_url
    end

  end


  context "manage" do

    before :each do
      @method=:get
      @action=:manage
      @params={ :id => @service.url_name, :facility_id => @authable.url_name }
    end

    it_should_allow_operators_only do
      response.should be_success
      response.should render_template('services/manage')
    end

  end
  
end

