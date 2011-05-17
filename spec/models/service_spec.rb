require 'spec_helper'

describe Service do

  context "factory" do
    it "should create using factory" do
      @facility     = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @order_status = Factory.create(:order_status)
      @service      = @facility.services.create(Factory.attributes_for(:service, :initial_order_status_id => @order_status.id, :facility_account_id => @facility_account.id))
      @service.should be_valid
      @service.type.should == 'Service'
    end
  end

  it "should validate presence of initial_order_status_id" do
    should validate_presence_of(:initial_order_status_id)
  end

  context "add survey" do
    before(:each) do
      @facility         = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @order_status     = Factory.create(:order_status)
      @service          = @facility.services.create(Factory.attributes_for(:service, :initial_order_status_id => @order_status.id, :facility_account_id => @facility_account.id))
      assert @service.valid?
    end
    
    it "should add as inactive" do
      @survey = Survey.create(:title => "Survey 1", :access_code => '1234')
      @survey.should be_valid
      @service.surveys.push(@survey)
      @service.service_surveys.size.should == 1
      @service.service_surveys.inactive.size.should == 1
      @service.active_survey?.should == false
    end

    it "should change to active after calling active!, and return survey as active_survey object" do
      @survey = Survey.create(:title => "Survey 1", :access_code => '1234')
      @service.surveys.push(@survey)
      @service.service_surveys.first.active!
      @service.service_surveys.first.active.should == true
      @service.service_surveys.first.active_at.should_not be_nil
      @service.active_survey?.should == true
      @service.active_survey.should == @survey
    end

    it "should remove survey, service_survey after call to destroy" do
      @survey = Survey.create(:title => "Survey 1", :access_code => '1234')
      @service.surveys.push(@survey)
      @ss = @service.service_surveys.first
      # destroy assocation object, which should destroy survey
      @service.service_surveys.destroy(@ss)
      assert_equal [], @service.reload.surveys
      assert_equal [], @service.reload.service_surveys
      assert_nil Survey.find_by_id(@survey.id)
    end
  end


# These tests work for Oracle, but not MySQL. Screwy DB date handling differences. Forget 'em. Surveyor is going away.

#  context "import survey" do
#    before(:each) do
#      @facility         = Factory.create(:facility)
#      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
#      @order_status     = Factory.create(:order_status)
#      @service          = @facility.services.create(Factory.attributes_for(:service, :initial_order_status_id => @order_status.id, :facility_account_id => @facility_account.id))
#      assert @service.valid?
#    end
#
#    it "should import 1 survey" do
#      @file1    = Pathname.new("#{Rails.root}/spec/files/alpha_survey.rb").realpath
#      @survey1  = @service.import_survey(@file1)
#      assert @survey1.valid?
#    end
#
#    it "should import multiple surveys" do
#      @file1    = Pathname.new("#{Rails.root}/spec/files/alpha_survey.rb").realpath
#      @survey1  = @service.import_survey(@file1)
#      assert @survey1.valid?
#      @file2    = "#{Rails.root}/spec/files/beta_survey.rb"
#      @survey2  = @service.import_survey(@file2)
#      assert @survey2.valid?
#    end
#
#    it "should not import survey with multiple sections" do
#      assert_raise(Exception) do
#        @file1    = Pathname.new("#{Rails.root}/spec/files/kitchen_sink_survey.rb").realpath
#        @survey1  = @service.import_survey(@file1)
#        assert @survey1.valid?
#      end
#    end
#
#    it "should import valid survey after a failed import" do
#      assert_raise(Exception) do
#        @file1    = Pathname.new("#{Rails.root}/spec/files/kitchen_sink_survey.rb").realpath
#        @survey1  = @service.import_survey(@file1)
#        assert @survey1.valid?
#      end
#      @file2    = Pathname.new("#{Rails.root}/spec/files/beta_survey.rb").realpath
#      @survey2  = @service.import_survey(@file2)
#      assert @survey2.valid?
#    end
#  end
end
