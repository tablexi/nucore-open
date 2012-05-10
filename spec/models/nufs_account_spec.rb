require 'spec_helper'

describe NufsAccount do
  context "account number validations" do
    before(:each) do
      @user     = Factory.create(:user)
      @owner    = Hash[:user => @user, :created_by => @user, :user_role => 'Owner']
      @options  = Hash[:description => "account description", :expires_at => Time.zone.now+1.day, :created_by => @user,
                       :account_users_attributes => [@owner]]
      @starts_at  = Time.zone.now-3.days
      @expires_at = Time.zone.now+3.days
    end

    it "should copy account_number to display_account_number" do
      @bcs = BudgetedChartString.create(:fund => '123', :dept => '1234567', :starts_at => @starts_at, :expires_at => @expires_at)
      @options[:account_number] = '123-1234567'
      @account = NufsAccount.create(@options)
      assert_equal '123-1234567', @account.account_number
    end

    it "should not have a facility" do
      facility = Factory.create(:facility)
      account = NufsAccount.create(@options)
      account.facility.should be_nil
    end

    it "should not be limited to a single facility" do
      NufsAccount.limited_to_single_facility?.should be_false
    end

  end
end
