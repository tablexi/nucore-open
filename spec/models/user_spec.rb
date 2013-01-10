require 'spec_helper'

describe User do


  before :each do
    @user=FactoryGirl.create(:user)
  end

  it "should validate uniquess of username" do
    # we need at least 1 user to test validations
    should validate_uniqueness_of(:username)
  end

  it { should have_many(:notifications) }

  it "should use factory" do
    @user.should be_valid
  end

  it "should belong to NU price group if the username does not have an \"@\" symbol" do
    @user.price_groups.include?(@nupg).should == true
  end

  it "should belong to External price group if the username has an \"@\" symbol" do
    user = User.new(FactoryGirl.attributes_for(:user))
    user.username = user.email
    user.save
    user.price_groups.include?(@epg).should == true
  end

  it "should be a member of any explicitly mapped price groups" do
    facility = FactoryGirl.create(:facility)
    pg       = facility.price_groups.create(FactoryGirl.attributes_for(:price_group))
    UserPriceGroupMember.create(:user => @user, :price_group => pg)
    @user.price_groups.include?(pg).should == true
  end

  it "should belong to price groups of accounts" do
    cc       = FactoryGirl.create(:nufs_account, :account_users_attributes => [{:user => @user, :created_by => @user, :user_role => 'Owner'}])
    facility = FactoryGirl.create(:facility)
    pg       = facility.price_groups.create(FactoryGirl.attributes_for(:price_group))
    AccountPriceGroupMember.create(:account => cc, :price_group => pg)
    @user.account_price_groups.include?(pg).should == true
  end

  it "should belong to price groups of account owner" do
    owner    = FactoryGirl.create(:user)
    cc       = FactoryGirl.create(:nufs_account, :account_users_attributes => [{:user => owner, :created_by => owner, :user_role => 'Owner'}])
    facility = FactoryGirl.create(:facility)
    pg       = facility.price_groups.create(FactoryGirl.attributes_for(:price_group))
    UserPriceGroupMember.create(:user => owner, :price_group => pg)

    cc.account_users.create(:user => @user, :created_by => owner, :user_role => 'Purchaser')

    @user.account_price_groups.include?(pg).should == true
  end

  it 'should be locally authenticated' do
    @user.should be_authenticated_locally
  end

  it 'should not be locally authenticated' do
    @user.encrypted_password=nil
    assert @user.save
    @user.should_not be_authenticated_locally
    @user.password_salt=nil
    assert @user.save
    @user.should_not be_authenticated_locally
  end

  it 'should alias username to login' do
    @user.should be_respond_to :login
    @user.username.should == @user.login
  end

  it 'should respond to ldap_attributes' do
    @user.should be_respond_to :ldap_attributes
  end

  it 'should not be external user' do
    @user.username.should_not == @user.email
    @user.should_not be_external
  end

  it 'should be external user' do
    @user.username=@user.email
    @user.should be_external
  end

  it "should belong to Cancer Center price group if the user is in the Cancer Center view"

  context 'cart' do
    before :each do
      @facility=FactoryGirl.create(:facility)
      @facility_account=@facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
      @item=@facility.items.create(FactoryGirl.attributes_for(:item, :facility_account_id => @facility_account.id))
      @order=@user.orders.create(FactoryGirl.attributes_for(:order, :created_by => @user.id, :facility => @facility))
      @price_group=FactoryGirl.create(:price_group, :facility => @facility)
      FactoryGirl.create(:user_price_group_member, :user => @user, :price_group => @price_group)
      @item_pp=@item.item_price_policies.create(FactoryGirl.attributes_for(:item_price_policy, :price_group_id => @price_group.id))
      @item_pp.reload.restrict_purchase=false
      @order_detail=@order.order_details.create(FactoryGirl.attributes_for(:order_detail, :product_id => @item.id))
    end

    it 'should return the order' do
      order=@user.cart
      order.should == @order
    end

    it 'should return the order when given created_by user' do
      order=@user.cart(@user)
      order.should == @order
    end

    it 'should return the existing unordered order even when its empty' do
      @order.order_details.destroy_all
      order = @user.cart(@user)
      order.reload.should == @order
    end

    it 'should return a new order' do
      order=@user.cart(@user, false)
      order.should_not == @order
      order.user.should == @user
      order.created_by.should == @user.id
    end

    it 'should return a new order when created_by user is nil' do
      order=@user.cart(nil, false)
      order.should_not == @order
      order.user.should == @user
      order.created_by.should == @user.id
    end
  end

  context 'accounts_for_product' do
    before :each do
      @facility=FactoryGirl.create(:facility)
      @facility_account=@facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
      @item=@facility.items.create(FactoryGirl.attributes_for(:item, :facility_account_id => @facility_account.id))
      @price_group=FactoryGirl.create(:price_group, :facility => @facility)
      FactoryGirl.create(:user_price_group_member, :user => @user, :price_group => @price_group)
      @item_pp=@item.item_price_policies.create(FactoryGirl.attributes_for(:item_price_policy, :price_group_id => @price_group.id))
      @item_pp.reload.restrict_purchase=false
      @account=FactoryGirl.create(:nufs_account, :account_users_attributes => [ FactoryGirl.attributes_for(:account_user, :user => @user) ])
    end

    it 'should not have an account because there is no price group' do
      UserPriceGroupMember.where(:price_group_id => @price_group.id, :user_id => @user.id).first.destroy
      @user.accounts_for_product(@item).should be_empty
    end

    it 'should have an account' do
      define_open_account @item.account, @account.account_number
      accts=@user.accounts_for_product(@item)
      accts.size.should == 1
      accts.first.should == @account
    end
  end

end
