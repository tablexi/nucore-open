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
      define_ge001(@options[:account_number])
      @account = NufsAccount.create(@options)
      assert @account.valid?
      assert_equal '123', @account.fund
      assert_equal '1234567', @account.dept
      # should initialize reader attributes after loading from database
      @account = NufsAccount.first
      assert_equal '123', @account.fund
      assert_equal '1234567', @account.dept
    end

    it "should copy account_number to display_account_number" do
      @bcs = BudgetedChartString.create(:fund => '123', :dept => '1234567', :starts_at => @starts_at, :expires_at => @expires_at)
      @options[:account_number] = '123-1234567'
      @account = NufsAccount.create(@options)
      assert_equal '123-1234567', @account.account_number
    end

    it "should allow format fund3-dept7-project8" do
      @options[:account_number] = '123-1234567-12345678'
      define_ge001(@options[:account_number])
      @account = NufsAccount.create(@options)
      assert @account.valid?
    end

    it "should allow format fund3-dept7-project8" do
      @options[:account_number] = '123-1234567-12345678'
      define_ge001(@options[:account_number])
      @account = NufsAccount.create(@options)
      assert @account.valid?
    end

    it "should allow format fund3-dept7-project8-activity2" do
      @options[:account_number] = '123-1234567-12345678-12'
      define_ge001(@options[:account_number])
      @account = NufsAccount.create(@options)
      assert @account.valid?
    end

    it "should allow format fund3-dept7-project8-activity2-program4" do
      # create chart string without program value
      @options[:account_number] = '123-1234567-12345678-12-1234'
      define_ge001(@options[:account_number])
      @account = NufsAccount.create(@options)
      assert @account.valid?
    end

    it "should not allow format fund3-dept7-project8-activity2-program4-account5" do
      # create chart string without program value
      @bcs = BudgetedChartString.create(:fund => '123', :dept => '1234567', :project => '12345678', :activity => '12',
                                        :account => '12345', :starts_at => @starts_at, :expires_at => @expires_at)
      @options[:account_number] = '123-1234567-12345678-12-1234-12345'
      @account = NufsAccount.create(@options)
      assert !@account.valid?
      assert @account.errors.on(:account_number)
    end

    it "should not allow invalid account number" do
      @options[:account_number] = '123'
      @account = NufsAccount.create(@options)
      assert !@account.valid?
      assert @account.errors.on(:account_number)
    end

    it "should not allow account that has expired" do
      @bcs = BudgetedChartString.create(:fund => '123', :dept => '1234567', :starts_at => @starts_at, :expires_at => @starts_at)
      @options[:account_number] = '123-1234567'
      @account = NufsAccount.create(@options)
      assert !@account.valid?
      assert_equal "not found or is inactive", @account.errors.on(:account_number)
    end

    it "should not allow account that has not started" do
      @bcs = BudgetedChartString.create(:fund => '123', :dept => '1234567', :starts_at => @starts_at+1.year, :expires_at => @expires_at)
      @options[:account_number] = '123-1234567'
      @account = NufsAccount.create(@options)
      assert !@account.valid?
      assert_equal "not found or is inactive", @account.errors.on(:account_number)
    end
  end
end
