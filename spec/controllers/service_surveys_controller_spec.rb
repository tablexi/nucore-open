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

  before(:all) do
    # remove objects; seems like running survey parser breaks the testing transaction model
#    ServiceSurvey.delete_all
#    Survey.delete_all
#    Service.delete_all
#    OrderStatus.delete_all
#    FacilityAccount.delete_all
#    Facility.delete_all
    create_users
  end

  before(:each) do
    @authable         = Factory.create(:facility)
    @facility_account = @authable.facility_accounts.create(Factory.attributes_for(:facility_account))
    @order_status     = Factory.create(:order_status)
    @service          = @authable.services.create(Factory.attributes_for(:service, :initial_order_status_id => @order_status.id, :facility_account_id => @facility_account.id))
  end

  context "create" do
    # uploading surveys has been moved to the file upload controller

    # it "should not allow facility director to create survey" do
    #   @auth.in_group!('director', ['Facility Director', @facility.pers_affiliate_id])
    #   @controller.stubs(:current_user).returns(@director)
    #   post :create, :facility_id => @facility.url_name, :service_id => @service.url_name, :survey => {:upload => nil}
    #   response.should render_template('403.html.erb')
    # end
    # 
    # it "should allow admin to create survey" do
    #   @controller.stubs(:current_user).returns(@admin)
    #   @request.env['HTTP_REFERER'] = "http://nucore.com/facilities/#{@facility.url_name}/services/#{@service.id}"
    #   @file = File.new("#{Rails.root}/spec/files/alpha_survey.rb")
    #   post :create, :facility_id => @facility.url_name, :service_id => @service.url_name,
    #                 :survey => {:upload => @file}
    #   assigns[:service].should == @service
    #   # should create survey
    #   Survey.count.should == 1
    #   @survey = Survey.first
    #   @survey.title.should == 'Alpha service survey'
    #   # should add to service survey collection
    #   @service.surveys.should == [@survey]
    # end
  end

  context "activate" do

    before(:each) do
      @file1            = "#{RAILS_ROOT}/spec/files/alpha_survey.rb"
      @survey1          = @service.import_survey(@file1)
      @file2            = "#{RAILS_ROOT}/spec/files/beta_survey.rb"
      @survey2          = @service.import_survey(@file2)
    end

    it "should allow admin to activate" do
      sign_in @admin
      @request.env['HTTP_REFERER'] = "http://nucore.com/facilities/#{@authable.url_name}/services/#{@service.url_name}"
      # activate first survey
      put :activate, :facility_id => @authable.url_name, :service_id => @service.url_name, :survey_code => @survey1.access_code
      assigns[:service].should == @service
      assigns[:survey].should == @survey1
      @service.surveys.should == [@survey1, @survey2]
      @service.active_survey?.should == true
      @service.service_surveys.active.size.should == 1
      @service.active_survey.should == @survey1
      # activate second survey
      put :activate, :facility_id => @authable.url_name, :service_id => @service.url_name, :survey_code => @survey2.access_code
      assigns[:service].should == @service
      assigns[:survey].should == @survey2
      @service.surveys.should == [@survey1, @survey2]
      @service.active_survey?.should == true
      # should active second survey and disable first
      @service.service_surveys.active.size.should == 1
      @service.reload.active_survey.should == @survey2
    end

  end
  
end