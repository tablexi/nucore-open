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

    it "should allow format fund3-dept7" do
      @options[:account_number] = '123-1234567'
      define_gl066(@options[:account_number])
      @account = NufsAccount.create(@options)
      assert @account.valid?
      assert_equal '123', @account.fund
      assert_equal '1234567', @account.dept
      # should initialize reader attributes after loading from database
      @account = NufsAccount.first
      @account.valid?
      assert_equal '123', @account.fund
      assert_equal '1234567', @account.dept
    end

    it "should copy account_number to display_account_number" do
      @bcs = BudgetedChartString.create(:fund => '123', :dept => '1234567', :starts_at => @starts_at, :expires_at => @expires_at)
      @options[:account_number] = '123-1234567'
      @account = NufsAccount.create(@options)
      assert_equal '123-1234567', @account.account_number
    end

    it "should not allow format fund3-dept7-project8" do
      assert_number_format('123-1234567-12345678', false)
    end

    it "should allow format fund3-dept7-project8-activity2 where fund is < 800 and activity is 01" do
      assert_number_format('123-1234567-12345678-01', true)
    end

    it "should not allow format fund3-dept7-project8-activity2 where fund is < 800 and activity is not 01" do
      assert_number_format('123-1234567-12345678-12', false)
    end

    it "should allow format fund3-dept7-project8-activity2 where fund is >= 800 and activity is not 01" do
      assert_number_format('800-1234567-12345678-12', true)
    end

    it "should allow format fund3-dept7-project8-activity2-program4" do
      assert_number_format '123-1234567-12345678-01-1234', true
    end

    it "should not allow format fund3-dept7-project8-activity2-program4-account5" do
      # create chart string without program value
      @bcs = BudgetedChartString.create(:fund => '123', :dept => '1234567', :project => '12345678', :activity => '12',
                                        :account => '12345', :starts_at => @starts_at, :expires_at => @expires_at)
      @options[:account_number] = '123-1234567-12345678-12-1234-12345'
      @account = NufsAccount.create(@options)
      assert !@account.valid?
      assert @account.errors[:account_number]
    end

    it "should not allow invalid account number" do
      @options[:account_number] = '123'
      @account = NufsAccount.create(@options)
      assert !@account.valid?
      assert @account.errors[:account_number]
    end

    it "should not allow account that has expired" do
      @bcs = BudgetedChartString.create(:fund => '123', :dept => '1234567', :starts_at => @starts_at, :expires_at => @starts_at)
      @options[:account_number] = '123-1234567'
      @account = NufsAccount.create(@options)
      assert !@account.valid?
      @account.errors[:account_number].should_not be_nil
    end

    it "should not allow account that has not started" do
      @bcs = BudgetedChartString.create(:fund => '123', :dept => '1234567', :starts_at => @starts_at+1.year, :expires_at => @expires_at)
      @options[:account_number] = '123-1234567'
      @account = NufsAccount.create(@options)
      assert !@account.valid?
      @account.errors[:account_number].should_not be_nil
    end

    it "should not have a facility" do
      facility = Factory.create(:facility)
      account = NufsAccount.create(@options)
      account.facility.should be_nil
    end

    private

    def assert_number_format(account_number, valid, gl066_override=nil)
      @options[:account_number] = account_number
      define_gl066(gl066_override ? gl066_override : @options[:account_number])
      @account = NufsAccount.create(@options)
      @account.valid?.should == valid
    end
  end
end
