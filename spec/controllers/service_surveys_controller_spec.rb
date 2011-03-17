require 'spec_helper'; require 'controller_spec_helper'

describe ServiceSurveysController do
  integrate_views

  it "should route" do
    # params_from(:get, "/facilities/alpha/services/1/surveys/upload").should == 
    #   {:controller => 'service_surveys', :action => 'upload', :facility_id => 'alpha', :service_id => '1'}
    params_from(:put, "/facilities/alpha/services/1/surveys/xyz/activate").should == 
      {:controller => 'service_surveys', :action => 'activate', :facility_id => 'alpha', :service_id => '1', :survey_code => 'xyz'}
    params_from(:put, "/facilities/alpha/services/1/surveys/xyz/deactivate").should == 
      {:controller => 'service_surveys', :action => 'deactivate', :facility_id => 'alpha', :service_id => '1', :survey_code => 'xyz'}
  end


  before(:all) { create_users }


  before(:each) do
    @authable         = Factory.create(:facility)
    @facility_account = @authable.facility_accounts.create(Factory.attributes_for(:facility_account))
    @order_status     = Factory.create(:order_status)
    @service          = @authable.services.create(Factory.attributes_for(:service, :initial_order_status_id => @order_status.id, :facility_account_id => @facility_account.id))
    @file1            = "#{RAILS_ROOT}/spec/files/alpha_survey.rb"
    @survey1          = @service.import_survey(@file1)
    @file2            = "#{RAILS_ROOT}/spec/files/beta_survey.rb"
    @survey2          = @service.import_survey(@file2)
    @request.env['HTTP_REFERER'] = "http://nucore.com/facilities/#{@authable.url_name}/services/#{@service.url_name}"
    @params={ :facility_id => @authable.url_name, :service_id => @service.url_name, :survey_code => @survey1.access_code }
  end


  context 'deactivate' do

    before(:each) do
      @method=:put
      @action=:deactivate
    end

    it_should_allow_managers_only :redirect do
      should redirect_to @request.env['HTTP_REFERER']
    end

    it 'should test more than auth'

  end


  context "activate" do

    before(:each) do
      @method=:put
      @action=:activate
    end

    it_should_allow_managers_only :redirect do
      assigns[:service].should == @service
      assigns[:survey].should == @survey1
      @service.surveys.should == [@survey1, @survey2]
      @service.active_survey?.should == true
      @service.service_surveys.active.size.should == 1
      @service.active_survey.should == @survey1
      # activate second survey
      @params[:survey_code]=@survey2.access_code
      do_request
      assigns[:service].should == @service
      assigns[:survey].should == @survey2
      @service.surveys.should == [@survey1, @survey2]
      @service.active_survey?.should == true
      # should active second survey and disable first
      @service.service_surveys.active.size.should == 1
      @service.reload.active_survey.should == @survey2
      should redirect_to @request.env['HTTP_REFERER']
    end

  end
  
end