require 'spec_helper'; require 'controller_spec_helper'

describe ServicesController do
  integrate_views

  it "should route" do
    params_from(:get, "/facilities/alpha/services").should == {:controller => 'services', :action => 'index', :facility_id => 'alpha'}
    params_from(:get, "/facilities/alpha/services/1/manage").should == {:controller => 'services', :action => 'manage', :id => '1', :facility_id => 'alpha'}
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
      response.should render_template('services/index.html.haml')
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
      response.should render_template('services/show.html.haml')
    end
  
    it_should_allow_all facility_users do
      assigns[:service].should == @service
      response.should be_success
      response.should render_template('services/show.html.haml')
    end

  end


  context 'new' do

    before :each do
      @method=:get
      @action=:new
    end

    it_should_allow_operators_only do
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

    it_should_allow_operators_only do
      should render_template 'edit.html.haml'
    end

  end


  context 'create' do

    before :each do
      @method=:post
      @action=:create
      @params.merge!(:service => Factory.attributes_for(:service, :facility_account_id => @facility_account.id))
    end

    it_should_allow_operators_only :redirect do
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

    it_should_allow_operators_only :redirect do
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

    it_should_allow_operators_only :redirect do
      assigns(:service).should == @service
      should_be_destroyed @service
      assert_redirected_to new_facility_service_url
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
      response.should render_template('services/manage.html.haml')
    end

  end
  
end

