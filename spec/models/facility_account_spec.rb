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

    it "should create using factory" do
      attrs=Factory.attributes_for(:facility_account)
      define_open_account(attrs[:revenue_account], attrs[:account_number])
      @facility_account = @facility.facility_accounts.create(attrs)
      assert @facility_account.valid?
    end

    context "revenue_account" do
      it "should not allow account < 5 digits" do
        @options[:revenue_account] = "9999"
        @account = FacilityAccount.create(@options)
        assert @account.invalid?
        assert @account.errors[:revenue_account]
      end
      
      it "should not allow account > 5 digits" do
        @options[:revenue_account] = "111111"
        @account = FacilityAccount.create(@options)
        assert @account.invalid?
        assert @account.errors[:revenue_account]
      end
    end

    it "should allow format fund3-dept7-project8" do
      @options[:account_number] = '123-1234567-12345678'
      define_open_account(@options[:revenue_account], @options[:account_number])
      @account = FacilityAccount.create(@options)
      assert @account.valid?
    end

    it "should allow format fund3-dept7-project8" do
      @options[:account_number] = '123-1234567-12345678'
      define_open_account(@options[:revenue_account], @options[:account_number])
      @account = FacilityAccount.create(@options)
      assert @account.valid?
    end

    it "should allow format fund3-dept7-project8-activity2" do
      @options[:account_number] = '123-1234567-12345678-12'
      define_open_account(@options[:revenue_account], @options[:account_number])
      @account = FacilityAccount.create(@options)
      assert @account.valid?
    end

    it "should not allow format fund3-dept7-project8-activity2-program4" do
      # create chart string without program value
      @options[:account_number] = '123-1234567-12345678-12-1234'
      define_open_account(@options[:revenue_account], @options[:account_number])
      @account = FacilityAccount.create(@options)
      assert @account.valid?
    end

    # we no longer validate facility accounts against BCS table
    #it "should not allow account that has expired" do
    #  @bcs = BudgetedChartString.create(:fund => '123', :dept => '1234567', :starts_at => @starts_at, :expires_at => @starts_at)
    #  @options[:account_number] = '123-1234567'
    #  @account = FacilityAccount.create(@options)
    #  assert !@account.valid?
    #  assert_equal "Account has expired", @account.errors[:base]
    #end

    # we no longer validate facility accounts against BCS table
    #it "should not allow account that has not started" do
    #  @bcs = BudgetedChartString.create(:fund => '123', :dept => '1234567', :starts_at => @starts_at+1.year, :expires_at => @expires_at)
    #  @options[:account_number] = '123-1234567'
    #  @account = FacilityAccount.create(@options)
    #  assert !@account.valid?
    #  assert_equal "Account is not active", @account.errors[:base]
    #end
  end
end
