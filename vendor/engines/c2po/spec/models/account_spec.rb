require 'spec_helper'

describe Account do
  before(:each) do
    @facility          = Factory.create(:facility)
    @user              = Factory.create(:user)
    @facility_account  = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
    @item              = @facility.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id))
  end

  it "should return error if the product facility does not accept purchase orders" do
    po_account = Factory.create(:purchase_order_account, :account_users_attributes => [{:user => @user, :created_by => @user, :user_role => 'Owner'}])
    po_account.validate_against_product(@item, @user).should == nil
    @facility.update_attributes(:accepts_po => false)
    @item.reload #load fresh facility with update attributes
    po_account.validate_against_product(@item, @user).should_not == nil
  end

  it "should return error if the product facility does not accept credit cards" do
    cc_account=Factory.create(:credit_card_account, :account_users_attributes => [{:user => @user, :created_by => @user, :user_role => 'Owner'}])
    cc_account.validate_against_product(@item, @user).should == nil
    @facility.update_attributes(:accepts_cc => false)
    @item.reload #load fresh facility with update attributes
    cc_account.validate_against_product(@item, @user).should_not == nil
  end
end