require 'spec_helper'
require 'account_cleaner'

describe AccountCleaner do

  before :each do
    @account                  = FactoryGirl.create(:setup_account, :expires_at => Time.zone.parse('2063-04-20 14:30:30'))
    @end_of_day_account       = FactoryGirl.create(:setup_account, :expires_at => Time.zone.parse('2063-04-21 23:59:59'))
    @beginning_of_day_account = FactoryGirl.create(:setup_account, :expires_at => Time.zone.parse('2063-04-22 00:00:00'))
  end

  context "update accounts.expires_at" do

    it "should not update if expires_at has a time other than beginning of day or end of day" do
      AccountCleaner.clean_expires_at(@account).should be_false
    end

    it "should not update if expires_at is set to end of day" do
      AccountCleaner.clean_expires_at(@end_of_day_account).should be_false
    end

    it "should update if expires_at is set to beginning of day" do
      AccountCleaner.clean_expires_at(@beginning_of_day_account).should be_true
    end

  end

end