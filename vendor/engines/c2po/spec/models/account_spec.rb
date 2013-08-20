require 'spec_helper'

describe Account do
  before(:each) do
    @facility          = FactoryGirl.create(:facility)
    @user              = FactoryGirl.create(:user)
    @facility_account  = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
    @item              = @facility.items.create(FactoryGirl.attributes_for(:item, :facility_account_id => @facility_account.id))
  end

  it "should return error if the product facility does not accept purchase orders" do
    po_account = FactoryGirl.create(:purchase_order_account, :account_users_attributes => [{:user => @user, :created_by => @user.id, :user_role => 'Owner'}])
    po_account.validate_against_product(@item, @user).should == nil
    @facility.update_attributes(:accepts_po => false)
    @item.reload #load fresh facility with update attributes
    po_account.validate_against_product(@item, @user).should_not == nil
  end

  it "should return error if the product facility does not accept credit cards" do
    cc_account=FactoryGirl.create(:credit_card_account, :account_users_attributes => [{:user => @user, :created_by => @user.id, :user_role => 'Owner'}])
    cc_account.validate_against_product(@item, @user).should == nil
    @facility.update_attributes(:accepts_cc => false)
    @item.reload #load fresh facility with update attributes
    cc_account.validate_against_product(@item, @user).should_not == nil
  end
end