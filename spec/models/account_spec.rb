require 'spec_helper'
require 'active_support/secure_random'

describe Account do
  it "should not create using factory" do
    @user    = FactoryGirl.create(:user)
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

  it { should belong_to(:affiliate)}

  it 'should be expired' do
    owner   = FactoryGirl.create(:user)
    hash     = Hash[:user => owner, :created_by => owner, :user_role => 'Owner']
    account = FactoryGirl.create(:nufs_account, :account_users_attributes => [hash])
    account.expires_at=Time.zone.now
    assert account.save
    account.should be_expired
  end

  it "should validate description <= 50 chars" do
    @user    = FactoryGirl.create(:user)
    hash     = Hash[:user => @user, :created_by => @user, :user_role => 'Owner']
    account = Account.new(FactoryGirl.attributes_for(:nufs_account, :account_users_attributes => [hash]))
    account.description = random_string = ActiveSupport::SecureRandom.hex(51)
    account.should_not be_valid
    account.should have(1).error_on(:description)
  end

  it "should set suspend_at on suspend and unsuspend" do
    @owner   = FactoryGirl.create(:user)
    hash     = Hash[:user => @owner, :created_by => @owner, :user_role => 'Owner']
    @account = FactoryGirl.create(:nufs_account, :account_users_attributes => [hash])
    assert_nothing_raised { @account.suspend! }
    @account.suspended_at.should_not == nil
    assert_nothing_raised { @account.unsuspend! }
    @account.suspended_at.should == nil
  end

  context "account users" do
    it "should find all the accounts a user has access to, default suspended? to false" do
      @user    = FactoryGirl.create(:user)
      hash     = Hash[:user => @user, :created_by => @user, :user_role => 'Owner']
      @account = FactoryGirl.create(:nufs_account, :account_users_attributes => [hash])
      @account.owner_user.should == @user
      @account.suspended?.should == false
    end

    it "should require an account owner" do
      @account = Account.create
      @account.errors[:base].should == ['Must have an account owner']
    end

    it "should find the non-deleted account owner" do
      @user1   = FactoryGirl.create(:user)
      hash1    = Hash[:user => @user1, :created_by => @user1, :user_role => 'Owner']
      @user2   = FactoryGirl.create(:user)
      hash2    = Hash[:user => @user2, :created_by => @user2, :user_role => 'Owner']
      @account = FactoryGirl.create(:nufs_account, :account_users_attributes => [hash1])

      @account.owner_user.should == @user1
      @account.owner.update_attributes(:deleted_at => Time.zone.now, :deleted_by => @user1.id)
      @account_user2 = @account.account_users.create(:user_id => @user2.id, :user_role => 'Owner', :created_by => @user2.id)
      @account.reload #load fresh account users with update attributes
      @account.owner_user.should == @user2
    end

    it "should find all non-suspended account business admins" do
      @owner   = FactoryGirl.create(:user)
      hash     = Hash[:user => @owner, :created_by => @owner, :user_role => 'Owner']
      @account = FactoryGirl.create(:nufs_account, :account_users_attributes => [hash])

      @user1   = FactoryGirl.create(:user)
      @user2   = FactoryGirl.create(:user)
      @account.account_users.create(:user_id => @user1.id, :user_role => 'Business Administrator', :created_by => @owner.id)
      @account.account_users.create(:user_id => @user2.id, :user_role => 'Business Administrator', :created_by => @owner.id, :deleted_at => Time.zone.now, :deleted_by => @owner.id)

      @account.business_admin_users.should include @user1
      @account.business_admin_users.should_not include @user2
    end

    it "should find all non-suspended business admins and the owner as notify users" do
      @owner   = FactoryGirl.create(:user)
      hash     = Hash[:user => @owner, :created_by => @owner, :user_role => 'Owner']
      @account = FactoryGirl.create(:nufs_account, :account_users_attributes => [hash])

      @user1   = FactoryGirl.create(:user)
      @user2   = FactoryGirl.create(:user)
      @account.account_users.create(:user_id => @user1.id, :user_role => 'Business Administrator', :created_by => @owner.id)
      @account.account_users.create(:user_id => @user2.id, :user_role => 'Business Administrator', :created_by => @owner.id, :deleted_at => Time.zone.now, :deleted_by => @owner.id)

      @account.notify_users.should include @owner
      @account.notify_users.should include @user1
      @account.notify_users.should_not include @user2
    end

    it "should verify if a user can purchase using the account" do
      @owner   = FactoryGirl.create(:user)
      hash     = Hash[:user => @owner, :created_by => @owner, :user_role => 'Owner']
      @account = FactoryGirl.create(:nufs_account, :account_users_attributes => [hash])

      @admin   = FactoryGirl.create(:user)
      @user    = FactoryGirl.create(:user)
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
      @facility          = FactoryGirl.create(:facility)
      @user              = FactoryGirl.create(:user)
      @nufs_account      = FactoryGirl.create(:nufs_account, :account_users_attributes => [{:user => @user, :created_by => @user, :user_role => 'Owner'}])
      @facility_account  = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
      @item              = @facility.items.create(FactoryGirl.attributes_for(:item, :facility_account_id => @facility_account.id))
      @price_group       = FactoryGirl.create(:price_group, :facility => @facility)
      @price_group_product=FactoryGirl.create(:price_group_product, :product => @item, :price_group => @price_group, :reservation_window => nil)
      @price_policy      = FactoryGirl.create(:item_price_policy, :product => @item, :price_group => @price_group)
      @pg_user_member    = FactoryGirl.create(:user_price_group_member, :user => @user, :price_group => @price_group)
    end

    it "should return nil if all conditions are met for validation" do
      define_open_account(@item.account, @nufs_account.account_number)
      @nufs_account.validate_against_product(@item, @user).should == nil
    end

    context 'bundles' do
      before :each do
        @item2 = @facility.items.create(FactoryGirl.attributes_for(:item, :account => 78960, :facility_account_id => @facility_account.id))
        @bundle = @facility.bundles.create(FactoryGirl.attributes_for(:bundle, :facility_account_id => @facility_account.id))
        [ @item, @item2 ].each do |item| 
          price_policy = item.item_price_policies.create(FactoryGirl.attributes_for(:item_price_policy, :price_group => @price_group))
          BundleProduct.create!(:quantity => 1, :product => item, :bundle => @bundle) 
        end
      end

      it "should not return error if the product is a bundle and both of the bundled product's accounts are open for a chart string" do
        [ @item, @item2 ].each{|item| define_open_account(item.account, @nufs_account.account_number) }
        @nufs_account.validate_against_product(@bundle, @user).should be_nil
      end
    end

    it "should return error if the product does not have a price policy for the account or user price groups" do
      define_open_account(@item.account, @nufs_account.account_number)
      @nufs_account.validate_against_product(@item, @user).should == nil
      @pg_user_member.destroy
      @user.reload
      @nufs_account.reload
      @nufs_account.validate_against_product(@item, @user).should_not == nil
      FactoryGirl.create(:price_group_product, :product => @item, :price_group => @price_group, :reservation_window => nil)
      @pg_account_member = FactoryGirl.create(:account_price_group_member, :account => @nufs_account, :price_group => @price_group)
      @nufs_account.reload #load fresh account with updated relationships
      @nufs_account.validate_against_product(@item, @user).should == nil
    end

  end

  it 'should update order details with statement' do
    facility = FactoryGirl.create(:facility)
    facility_account = facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
    user     = FactoryGirl.create(:user)
    item     = facility.items.create(FactoryGirl.attributes_for(:item, :facility_account_id => facility_account.id))
    account  = FactoryGirl.create(:nufs_account, :account_users_attributes => [Hash[:user => user, :created_by => user, :user_role => 'Owner']])
    order    = user.orders.create(FactoryGirl.attributes_for(:order, :created_by => user.id, :facility => facility))
    order_detail = order.order_details.create!(FactoryGirl.attributes_for(:order_detail, :reviewed_at => (Time.zone.now-1.day)).update(:product_id => item.id, :account_id => account.id))
    statement = Statement.create({:facility => facility, :created_by => 1, :account => account})
    account.update_order_details_with_statement(statement)
    order_detail.reload.statement.should == statement
  end


  context "billing" do
    before(:each) do
      @facility1        = FactoryGirl.create(:facility)
      @facility2        = FactoryGirl.create(:facility)
      @user             = FactoryGirl.create(:user)
      @account          = FactoryGirl.create(:nufs_account, :account_users_attributes => [{:user => @user, :created_by => @user, :user_role => 'Owner'}])
    end

    it "should find all accounts that need statements for a facility"

    it "should return the correct billable balance for a facility"

    it "should return the correct pending balance for a facility"

    it "should return the correct facility balance for a given date"

    it "should return the most recent account statement for a given facility"
  end

  unless AccountManager::FACILITY_ACCOUNT_CLASSES.empty?
    context "limited facilities" do
      before :each do
        @user             = FactoryGirl.create(:user)
        @facility1        = FactoryGirl.create(:facility)
        @facility2        = FactoryGirl.create(:facility)
        @nufs_account = FactoryGirl.create(:nufs_account, :account_users_attributes => [{:user => @user, :created_by => @user, :user_role => 'Owner'}])
        @facility1_accounts, @facility2_accounts=[ @nufs_account ], [ @nufs_account ]

        AccountManager::FACILITY_ACCOUNT_CLASSES.each do |class_name|
          class_sym=class_name.underscore.to_sym
          @facility1_accounts << FactoryGirl.create(class_sym, :account_users_attributes => [{:user => @user, :created_by => @user, :user_role => 'Owner'}], :facility => @facility1)
          @facility2_accounts << FactoryGirl.create(class_sym, :account_users_attributes => [{:user => @user, :created_by => @user, :user_role => 'Owner'}], :facility => @facility2)
        end
      end

      it "should return the right accounts" do
        Account.for_facility(@facility1).should contain_all @facility1_accounts
        Account.for_facility(@facility2).should contain_all @facility2_accounts
      end
    end
  end
end
