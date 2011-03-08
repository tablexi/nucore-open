require 'spec_helper'

describe PaymentAccountTransaction do
  it "should create using valid attributes" do
    @facility    = Factory.create(:facility)
    @fa          = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
    @user        = Factory.create(:user)
    @account     = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])

    @account_txn = @account.payment_account_transactions.create({:facility_id => @facility.id, :transaction_amount => -1,
                                                                 :is_in_dispute => false,
                                                                 :created_by => @user.id, :reference => '12345', 
                                                                 :finalized_at => Time.zone.now})
    @account_txn.should be_valid
  end
  
  it "should require a negative transaction amount" do
    @account_txn = PaymentAccountTransaction.new({:transaction_amount => -1})
    @account_txn.valid?
    @account_txn.errors.on(:transaction_amount).should be_nil

    @account_txn = PaymentAccountTransaction.new({:transaction_amount => 1})
    @account_txn.valid?
    @account_txn.errors.on(:transaction_amount).should_not be_nil
  end

  it "should require a finalized at date" do
    @account_txn = PaymentAccountTransaction.new({:finalized_at => Time.zone.now})
    @account_txn.valid?
    @account_txn.errors.on(:finalized_at).should be_nil

    @account_txn = PaymentAccountTransaction.new()
    @account_txn.valid?
    @account_txn.errors.on(:finalized_at).should_not be_nil
  end
  
  it "should require a reference" do
    @account_txn = PaymentAccountTransaction.new({:reference => '12345'})
    @account_txn.valid?
    @account_txn.errors.on(:reference).should be_nil

    @account_txn = PaymentAccountTransaction.new()
    @account_txn.valid?
    @account_txn.errors.on(:reference).should_not be_nil
  end
end