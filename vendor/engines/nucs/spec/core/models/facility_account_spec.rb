require 'spec_helper'

describe FacilityAccount do
  context "valid account number" do
    before(:each) do
      @user     = Factory.create(:user)
      @facility = Factory.create(:facility)
      assert @facility.valid?
      @options  = Hash[:is_active => 1, :created_by => @user, :facility_id => @facility.id, :revenue_account => 10000]
      @starts_at  = Time.zone.now-3.days
      @expires_at = Time.zone.now+3.days
    end

    it "should allow format fund3-dept7" do
      @options[:account_number] = '123-1234567'
      define_open_account(@options[:revenue_account], @options[:account_number])
      @account = FacilityAccount.create(@options)
      assert @account.valid?
      assert_equal '123', @account.fund
      assert_equal '1234567', @account.dept
      # should initialize reader attributes after loading from database
      @account = FacilityAccount.first
      assert_equal '123', @account.fund
      assert_equal '1234567', @account.dept
    end

    # accounts should not be part of the account_number string
    it "should not allow format fund3-dept7-project8-activity2-program4-account5" do
      # create chart string without program value
      @options[:account_number] = '123-1234567-12345678-12-1234-12345'
      @account = FacilityAccount.create(@options)
      assert !@account.valid?
      assert @account.errors[:account_number]
    end

    it "should not allow invalid account number" do
      @options[:account_number] = '123'
      @account = FacilityAccount.create(@options)
      assert !@account.valid?
      assert @account.errors[:account_number]
    end

  end
end
