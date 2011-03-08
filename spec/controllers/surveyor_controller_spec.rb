require 'spec_helper'; require 'controller_spec_helper'

describe SurveyorController do
  integrate_views

  it "should route" do
    params_from(:get, "/orders/1/details/5/surveys/xyz").should ==
                {:controller => 'surveyor', :action => 'create', :order_id => '1', :od_id => '5', :survey_code => 'xyz'}
    params_from(:get, "/facilities/1/services/1/surveys/xyz/preview").should ==
                {:controller => 'surveyor', :action => 'preview', :facility_id => '1', :service_id => '1', :survey_code => 'xyz'}
  end

  before(:all) { create_users }


  before :each do
    @authable          = Factory.create(:facility)
    @facility_account  = @authable.facility_accounts.create(Factory.attributes_for(:facility_account))
    @order_status      = Factory.create(:order_status)
    @service           = @authable.services.create(Factory.attributes_for(:service, :initial_order_status_id => @order_status.id, :facility_account_id => @facility_account.id))
    @file1            = "#{RAILS_ROOT}/spec/files/alpha_survey.rb"
    @survey1          = @service.import_survey(@file1)
  end


  context "preview" do

    before(:each) do
      @method=:get
      @action=:preview
      @params={ :facility_id => @authable.url_name, :service_id => @service.url_name, :survey_code => @survey1.access_code }
    end

    it_should_allow_operators_only do
      assigns[:service].should == @service
      assigns[:survey].should == @survey1
      assigns[:response_set].valid?.should == true
      service_survey = @service.service_surveys.find_by_survey_id(@survey1.id)
      service_survey.preview_code.should == assigns[:response_set].access_code
      response_set_count = ResponseSet.count
      # subsequent requests should return the same response set object
      get :preview, :facility_id => @authable.url_name, :service_id => @service.url_name, :survey_code => @survey1.access_code
      assigns[:service].should == @service
      assigns[:survey].should == @survey1
      service_survey.preview_code.should == assigns[:response_set].access_code
      response_set_count.should == ResponseSet.count
    end

  end

  context "create" do

    before(:each) do
      @price_group       = @authable.price_groups.create(Factory.attributes_for(:price_group))
      # find guest user
      @user              = @guest
      @account           = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
      # create order + order detail
      @order             = @user.orders.create(Factory.attributes_for(:order, :created_by => @user.id, :account => @account))
      @order.add(@service, 1)
      @order_detail      = @order.order_details.first

      @method=:get
      @action=:create
      @params={ :order_id => @order.id, :od_id => @order_detail.id, :survey_code => @survey1.access_code }
    end


    it_should_allow :guest do
      assigns[:order].should == @order
      assigns[:detail].should == @order_detail
      assigns[:survey].should == @survey1
      @response_set = assigns[:response_set]
      response.should redirect_to "/orders/#{@order.id}/details/#{@order_detail.id}/surveys/#{@survey1.access_code}/#{@response_set.access_code}/edit"
    end

  end

end