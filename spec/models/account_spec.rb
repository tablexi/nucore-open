require 'spec_helper'
require 'active_support/secure_random'

describe Account do
  it "should not create using factory" do
    @user    = Factory.create(:user)
    hash     = Hash[:user => @user, :created_by => @user, :user_role => 'Owner']
    @account = create_nufs_account_with_owner :user

    @account.errors[:type].should_not be_nil
  end

  it "should require account_number" do
    should validate_presence_of(:account_number)
  end

  it "should require expires_at" do
    should validate_presence_of(:expires_at)
  end

  it "should validate description <= 50 chars" do
    @user    = Factory.create(:user)
    hash     = Hash[:user => @user, :created_by => @user, :user_role => 'Owner']
    account = Account.new(Factory.attributes_for(:nufs_account, :account_users_attributes => [hash]))
    account.description = random_string = ActiveSupport::SecureRandom.hex(51)
    account.should_not be_valid
    account.should have(1).error_on(:description)
  end

  it "should set suspend_at on suspend and unsuspend" do
    @owner   = Factory.create(:user)
    hash     = Hash[:user => @owner, :created_by => @owner, :user_role => 'Owner']
    @account = Factory.create(:nufs_account, :account_users_attributes => [hash])
    @account.suspend!
    @account.suspended_at.should_not == nil
    @account.unsuspend!
    @account.suspended_at.should == nil
  end

  context "account users" do
    it "should find all the accounts a user has access to, default suspended? to false" do
      @user    = Factory.create(:user)
      hash     = Hash[:user => @user, :created_by => @user, :user_role => 'Owner']
      @account = Factory.create(:nufs_account, :account_users_attributes => [hash])
      @account.owner_user.should == @user
      @account.suspended?.should == false
    end

    it "should require an account owner" do
      @account = Account.create
      @account.errors[:base].should == ['Must have an account owner']
    end

    it "should find the non-deleted account owner" do
      @user1   = Factory.create(:user)
      hash1    = Hash[:user => @user1, :created_by => @user1, :user_role => 'Owner']
      @user2   = Factory.create(:user)
      hash2    = Hash[:user => @user2, :created_by => @user2, :user_role => 'Owner']
      @account = Factory.create(:nufs_account, :account_users_attributes => [hash1])

      @account.owner_user.should == @user1
      @account.owner.update_attributes(:deleted_at => Time.zone.now, :deleted_by => @user1.id)
      @account_user2 = @account.account_users.create(:user_id => @user2.id, :user_role => 'Owner', :created_by => @user2.id)
      @account.reload #load fresh account users with update attributes
      @account.owner_user.should == @user2
    end

    it "should find all non-suspended account business admins" do
      @owner   = Factory.create(:user)
      hash     = Hash[:user => @owner, :created_by => @owner, :user_role => 'Owner']
      @account = Factory.create(:nufs_account, :account_users_attributes => [hash])

      @user1   = Factory.create(:user)
      @user2   = Factory.create(:user)
      @account.account_users.create(:user_id => @user1.id, :user_role => 'Business Administrator', :created_by => @owner.id)
      @account.account_users.create(:user_id => @user2.id, :user_role => 'Business Administrator', :created_by => @owner.id, :deleted_at => Time.zone.now, :deleted_by => @owner.id)

      @account.business_admin_users.should include @user1
      @account.business_admin_users.should_not include @user2
    end

    it "should find all non-suspended business admins and the owner as notify users" do
      @owner   = Factory.create(:user)
      hash     = Hash[:user => @owner, :created_by => @owner, :user_role => 'Owner']
      @account = Factory.create(:nufs_account, :account_users_attributes => [hash])

      @user1   = Factory.create(:user)
      @user2   = Factory.create(:user)
      @account.account_users.create(:user_id => @user1.id, :user_role => 'Business Administrator', :created_by => @owner.id)
      @account.account_users.create(:user_id => @user2.id, :user_role => 'Business Administrator', :created_by => @owner.id, :deleted_at => Time.zone.now, :deleted_by => @owner.id)

      @account.notify_users.should include @owner
      @account.notify_users.should include @user1
      @account.notify_users.should_not include @user2
    end

    it "should verify if a user can purchase using the account" do
      @owner   = Factory.create(:user)
      hash     = Hash[:user => @owner, :created_by => @owner, :user_role => 'Owner']
      @account = Factory.create(:nufs_account, :account_users_attributes => [hash])

      @admin   = Factory.create(:user)
      @user    = Factory.create(:user)
      @account.account_users.create(:user_id => @admin.id, :user_role => 'Business Administrator', :created_by => @owner.id)
      @user_au = @account.account_users.create(:user_id => @user.id, :user_role => 'Purchaser', :created_by => @owner.id)

      @account.can_be_used_by?(@owner).should == true
      @account.can_be_used_by?(@admin).should == true
      @account.can_be_used_by?(@user).should == true

      @user_au.update_attributes(:deleted_at => Time.zone.now, :deleted_by => @owner.id)
      @account.can_be_used_by?(@user).should == false
    end
  end

  context "validation against product/user" do
    before(:each) do
      @facility          = Factory.create(:facility)
      @user              = Factory.create(:user)
      @nufs_account      = Factory.create(:nufs_account, :account_users_attributes => [{:user => @user, :created_by => @user, :user_role => 'Owner'}])
      @facility_account  = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @item              = @facility.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id))
      @price_group       = Factory.create(:price_group, :facility => @facility)
      @price_group_product=Factory.create(:price_group_product, :product => @item, :price_group => @price_group, :reservation_window => nil)
      @price_policy      = Factory.create(:item_price_policy, :item => @item, :price_group => @price_group)
      @pg_user_member    = Factory.create(:user_price_group_member, :user => @user, :price_group => @price_group)
    end

    it "should return nil if all conditions are met for validation" do
      define_open_account(@item.account, @nufs_account.account_number)
      @nufs_account.validate_against_product(@item, @user).should == nil
    end

    it "should return error if the product facility does not accept account type for payment" do
      @po_account = Factory.create(:purchase_order_account, :account_users_attributes => [{:user => @user, :created_by => @user, :user_role => 'Owner'}])
      @po_account.validate_against_product(@item, @user).should == nil
      @facility.update_attributes(:accepts_po => false)
      @item.reload #load fresh facility with update attributes
      @po_account.validate_against_product(@item, @user).should_not == nil

      @cc_account  = Factory.create(:credit_card_account, :account_users_attributes => [{:user => @user, :created_by => @user, :user_role => 'Owner'}])
      @cc_account.validate_against_product(@item, @user).should == nil
      @facility.update_attributes(:accepts_cc => false)
      @item.reload #load fresh facility with update attributes
      @cc_account.validate_against_product(@item, @user).should_not == nil
    end

    it "should return error if the product does not have a price policy for the account or user price groups" do
      define_open_account(@item.account, @nufs_account.account_number)
      @nufs_account.validate_against_product(@item, @user).should == nil
      @price_group_product.destroy
      @nufs_account.validate_against_product(@item, @user).should_not == nil
      Factory.create(:price_group_product, :product => @item, :price_group => @price_group, :reservation_window => nil)
      @pg_account_member = Factory.create(:account_price_group_member, :account => @nufs_account, :price_group => @price_group)
      @nufs_account.reload #load fresh account with updated relationships
      @nufs_account.validate_against_product(@item, @user).should == nil
    end

    it "should return error if the chart string account does not product account number"
  end

  it 'should update order details with statement' do
    facility = Factory.create(:facility)
    facility_account = facility.facility_accounts.create(Factory.attributes_for(:facility_account))
    user     = Factory.create(:user)
    item     = facility.items.create(Factory.attributes_for(:item, :facility_account_id => facility_account.id))
    account  = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => user, :created_by => user, :user_role => 'Owner']])
    order    = user.orders.create(Factory.attributes_for(:order, :created_by => user.id, :facility => facility))
    order_detail = order.order_details.create!(Factory.attributes_for(:order_detail, :reviewed_at => (Time.zone.now-1.day)).update(:product_id => item.id, :account_id => account.id))
    statement = Statement.create({:facility => facility, :created_by => 1, :account => account})
    account.update_order_details_with_statement(statement)
    order_detail.reload.statement.should == statement
  end


  context "billing" do
    before(:each) do
      @facility1        = Factory.create(:facility)
      @facility2        = Factory.create(:facility)
      @user             = Factory.create(:user)
      @account          = Factory.create(:nufs_account, :account_users_attributes => [{:user => @user, :created_by => @user, :user_role => 'Owner'}])
    end

    it "should find all accounts that need statements for a facility"

    it "should return the correct billable balance for a facility"

    it "should return the correct pending balance for a facility"

    it "should return the correct facility balance for a given date"

    it "should return the most recent account statement for a given facility"
  end
end
