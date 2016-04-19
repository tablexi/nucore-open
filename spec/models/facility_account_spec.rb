require "rails_helper"

RSpec.describe FacilityAccount do
  context "valid account number" do
    before(:each) do
      @user     = FactoryGirl.create(:user)
      @facility = FactoryGirl.create(:facility)
      assert @facility.valid?
      @options = Hash[is_active: 1, created_by: @user.id, facility_id: @facility.id, revenue_account: 51_234]
      @starts_at  = Time.zone.now - 3.days
      @expires_at = Time.zone.now + 3.days
    end

    it "should create using factory" do
      attrs = FactoryGirl.attributes_for(:facility_account)
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
  end
end
