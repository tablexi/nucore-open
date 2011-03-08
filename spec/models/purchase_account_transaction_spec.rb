require 'spec_helper'

describe PurchaseAccountTransaction do
  it "should create using valid attributes" do
    @facility     = Factory.create(:facility)
    @fa           = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
    @user         = Factory.create(:user)
    @item         = @facility.items.create(Factory.attributes_for(:item, :facility_account_id => @fa.id))
    @item.should be_valid
    @account      = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
    @order        = @user.orders.create(Factory.attributes_for(:order, :created_by => @user.id))
    @order.should be_valid
    @order_detail = @order.order_details.create(Factory.attributes_for(:order_detail).update(:product_id => @item.id, :account_id => @account.id))
    @order_detail.should be_valid

    @account_txn  = @order_detail.purchase_account_transactions.create({:account_id => @account.id, :facility_id => @facility.id,
                                                                        :is_in_dispute => false,
                                                                        :transaction_amount => 11,
                                                                        :created_by => @user.id, :finalized_at => Time.zone.now})
    @account_txn.should be_valid
  end
  
  it "should require a positive transaction amount" do
    @account_txn = PurchaseAccountTransaction.new({:transaction_amount => 1})
    @account_txn.valid?
    @account_txn.errors.on(:transaction_amount).should be_nil

    @account_txn = PurchaseAccountTransaction.new({:transaction_amount => -1})
    @account_txn.valid?
    @account_txn.errors.on(:transaction_amount).should_not be_nil
  end

  it "should require an order detail" do
    @account_txn = PurchaseAccountTransaction.new({:order_detail_id => 1})
    @account_txn.valid?
    @account_txn.errors.on(:order_detail_id).should be_nil

    @account_txn = PurchaseAccountTransaction.new()
    @account_txn.valid?
    @account_txn.errors.on(:order_detail_id).should_not be_nil
  end
end