require 'spec_helper'
require 'affiliate_account_helper'

describe PurchaseOrderAccount do
  include AffiliateAccountHelper

  before(:each) do
    @user=FactoryGirl.create(:user)

    @owner={
        :user => @user,
        :created_by => @user.id,
        :user_role => 'Owner'
    }

    @account_attrs={
        :account_number => '4111-1111-1111-1111',
        :description => "account description",
        :expires_at => Time.zone.now + 1.year,
        :created_by => @user.id,
        :account_users_attributes => [@owner],
    }
  end


  it "should handle facilities" do
    account1 = PurchaseOrderAccount.create(@account_attrs)
    account1.should respond_to(:facility)
  end

  it "should take a facility" do
    facility = FactoryGirl.create(:facility)
    @account_attrs[:facility] = facility
    account = PurchaseOrderAccount.create(@account_attrs)
    account.facility.should == facility
  end

  it "should be limited to a single facility" do
    PurchaseOrderAccount.limited_to_single_facility?.should be_true
  end


  context 'with facility' do
    let(:facility) { FactoryGirl.create :facility }
    let(:account) do
      @account_attrs[:facility] = facility
      PurchaseOrderAccount.create @account_attrs
    end

    it 'should include the facility in the description' do
      account.to_s.should include(account.facility.name)
    end

    it "should take a facility" do
      account.facility.should == facility
    end
  end

end
