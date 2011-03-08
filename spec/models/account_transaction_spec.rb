require 'spec_helper'

describe AccountTransaction do
  it "should not create using factory" do
    @facility    = Factory.create(:facility)
    @user        = Factory.create(:user)
    @account     = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
    @account_txn = AccountTransaction.create({:account_id => @account.id, :facility_id => @facility.id, :created_by => 1})

    @account_txn.errors.on(:type).should_not be_nil
  end
end