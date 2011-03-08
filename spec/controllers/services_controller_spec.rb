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
  end


  context "index" do

    before :each do
      @method=:get
      @action=:index
      @params={ :facility_id => @authable.url_name }
    end

    it_should_deny :guest

    it_should_allow_all facility_operators do
      assigns[:services].should == [@service]
      response.should be_success
      response.should render_template('services/index.html.haml')
    end

  end


  context "manage" do

    before :each do
      @method=:get
      @action=:manage
      @params={ :id => @service.url_name, :facility_id => @authable.url_name }
    end

    it_should_deny :guest

    it_should_allow_all facility_operators do
      response.should be_success
      response.should render_template('services/manage.html.haml')
    end

  end


  context "show" do

    before :each do
      @method=:get
      @action=:show
      @params={ :id => @service.url_name, :facility_id => @authable.url_name }
    end

    it "should allow public access" do
      do_request
      assigns[:service].should == @service
      response.should be_success
      response.should render_template('services/show.html.haml')
    end
  
    it_should_allow_all ([ :guest ]+ facility_operators) do
      assigns[:service].should == @service
      response.should be_success
      response.should render_template('services/show.html.haml')
    end

  end
  
end

