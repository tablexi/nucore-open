require 'spec_helper'

describe Order do
  before(:each) do
    @facility     = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @price_group  = @facility.price_groups.create(Factory.attributes_for(:price_group))
      @order_status = Factory.create(:order_status)
      @service      = @facility.services.create(Factory.attributes_for(:service, :initial_order_status_id => @order_status.id, :facility_account_id => @facility_account.id))
      @service_pp   = Factory.create(:service_price_policy, :service => @service, :price_group => @price_group)
      @user         = Factory.create(:user)
      @pg_member    = Factory.create(:user_price_group_member, :user => @user, :price_group => @price_group)
      @account      = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
      @order        = @user.orders.create(Factory.attributes_for(:order, :created_by => @user.id, :account => @account, :facility => @facility))
  end


  it "should not allow validate if the account type is not allowed by the facility" do
    # facility does not accept credit card accounts
    @facility.accepts_cc = false
    @facility.save
    # create credit card account and link to order
    @cc_account = Factory.create(:credit_card_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
    @order = @user.orders.create(Factory.attributes_for(:order, :created_by => @user.id, :account => @cc_account, :facility => @facility))
    @order.order_details.create(:product_id => @service.id, :quantity => 1)
    # should not be allowed to purchase with a credit card account
    @order.validate_order!.should be false
  end
end