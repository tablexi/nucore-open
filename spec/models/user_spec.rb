require "rails_helper"

RSpec.describe User do


  before :each do
    @user=FactoryGirl.create(:user)
  end

  it "should validate uniquess of username" do
    # we need at least 1 user to test validations
    is_expected.to validate_uniqueness_of(:username)
  end

  it 'should save the username as lowercase' do
    @user = FactoryGirl.create(:user, :username => 'AnEmail@example.org')
    expect(@user.reload.username).to eq('anemail@example.org')
  end

  it { is_expected.to have_many(:notifications) }

  it "should use factory" do
    expect(@user).to be_valid
  end

  it "should belong to NU price group if the username does not have an \"@\" symbol" do
    expect(@user.price_groups.include?(@nupg)).to eq(true)
  end

  it "should belong to External price group if the username has an \"@\" symbol" do
    user = User.new(FactoryGirl.attributes_for(:user))
    user.username = user.email
    user.save
    expect(user.price_groups.include?(@epg)).to eq(true)
  end

  it "should be a member of any explicitly mapped price groups" do
    facility = FactoryGirl.create(:facility)
    pg       = facility.price_groups.create(FactoryGirl.attributes_for(:price_group))
    UserPriceGroupMember.create(:user => @user, :price_group => pg)
    expect(@user.price_groups.include?(pg)).to eq(true)
  end

  it "should belong to price groups of accounts" do
    cc       = FactoryGirl.create(:nufs_account, :account_users_attributes => account_users_attributes_hash(:user => @user))
    facility = FactoryGirl.create(:facility)
    pg       = facility.price_groups.create(FactoryGirl.attributes_for(:price_group))
    AccountPriceGroupMember.create(:account => cc, :price_group => pg)
    expect(@user.account_price_groups.include?(pg)).to eq(true)
  end

  it "should belong to price groups of account owner" do
    owner    = FactoryGirl.create(:user)
    cc       = FactoryGirl.create(:nufs_account, :account_users_attributes => account_users_attributes_hash(:user => owner))
    facility = FactoryGirl.create(:facility)
    pg       = facility.price_groups.create(FactoryGirl.attributes_for(:price_group))
    UserPriceGroupMember.create(:user => owner, :price_group => pg)

    cc.account_users.create(:user => @user, :created_by => owner.id, :user_role => 'Purchaser')

    expect(@user.account_price_groups.include?(pg)).to eq(true)
  end

  it 'should be locally authenticated' do
    expect(@user).to be_authenticated_locally
  end

  it 'should not be locally authenticated' do
    @user.encrypted_password=nil
    assert @user.save
    expect(@user).not_to be_authenticated_locally
    @user.password_salt=nil
    assert @user.save
    expect(@user).not_to be_authenticated_locally
  end

  it 'should alias username to login' do
    expect(@user).to be_respond_to :login
    expect(@user.username).to eq(@user.login)
  end

  it 'should respond to ldap_attributes' do
    expect(@user).to be_respond_to :ldap_attributes
  end

  it 'should not be external user' do
    expect(@user.username).not_to eq(@user.email)
    expect(@user).not_to be_external
  end

  it 'should be external user' do
    @user.username=@user.email
    expect(@user).to be_external
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
      expect(order).to eq(@order)
    end

    it 'should return the order when given created_by user' do
      order=@user.cart(@user)
      expect(order).to eq(@order)
    end

    it 'should return the existing unordered order even when its empty' do
      @order.order_details.destroy_all
      order = @user.cart(@user)
      expect(order.reload).to eq(@order)
    end

    it 'should return a new order' do
      order=@user.cart(@user, false)
      expect(order).not_to eq(@order)
      expect(order.user).to eq(@user)
      expect(order.created_by).to eq(@user.id)
    end

    it 'should return a new order when created_by user is nil' do
      order=@user.cart(nil, false)
      expect(order).not_to eq(@order)
      expect(order.user).to eq(@user)
      expect(order.created_by).to eq(@user.id)
    end
  end

  context 'accounts_for_product' do
    before :each do
      @facility=FactoryGirl.create(:facility)
      @facility_account=@facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
      @item=@facility.items.create(FactoryGirl.attributes_for(:item, :facility_account_id => @facility_account.id))
      @price_group=FactoryGirl.create(:price_group, :facility => @facility)
      @item_pp=@item.item_price_policies.create(FactoryGirl.attributes_for(:item_price_policy, :price_group_id => @price_group.id))
      @item_pp.reload.restrict_purchase=false
      @account=FactoryGirl.create(:nufs_account, :account_users_attributes => [ FactoryGirl.attributes_for(:account_user, :user => @user) ])
      create(:account_price_group_member, account: @account, price_group: @price_group)
    end

    it 'should not have an account because there is no price group' do
      AccountPriceGroupMember.where(account_id: @account.id, price_group_id: @price_group.id).first.destroy
      expect(@user.accounts_for_product(@item)).to be_empty
    end

    it 'should have an account' do
      define_open_account @item.account, @account.account_number
      accts=@user.accounts_for_product(@item)
      expect(accts.size).to eq(1)
      expect(accts.first).to eq(@account)
    end
  end

  describe "#recently_used_facilities" do
    subject { user.recently_used_facilities(limit) }
    let(:account) { create(:setup_account, owner: user) }
    let(:facilities) { products.map(&:facility) }
    let(:limit) { 5 }
    let(:products) { create_list(:setup_item, 6) }
    let(:user) { create(:user) }

    context "when the user has no orders" do
      it { expect(subject).to be_empty }
    end

    context "a user has made an update very recently" do
      let!(:old_order) { create(:setup_order, :purchased, account: account, product: products.first, user: user, ordered_at: 1.week.ago) }
      let!(:new_order) { create(:setup_order, :purchased, account: account, product: products.second, user: user, ordered_at: 1.day.ago) }
      let!(:unpurchased_order) { create(:setup_order, account: account, product: products.third, user: user) }

      context "bubbling up the newest" do
        let(:limit) { 1 }
        it { is_expected.to eq([facilities.second]) }
      end

      context "ordering by name" do
        let(:limit) { 2 }
        it { is_expected.to eq(facilities.first(2)) }
      end

      context "excludes unpurchased" do
        let(:limit) { 3 }
        it { is_expected.to eq(facilities.first(2)) }
      end
    end

    context "when the user has orders" do
      before(:each) do
        products.first(order_count).each_with_index do |product, i|
          create(:setup_order, :purchased, account: account, product: product, user: user, ordered_at: i.days.ago)
        end
      end

      context "made in fewer than 5 facilities" do
        let(:order_count) { 4 }

        it { expect(subject).to eq(facilities.first(order_count)) }
      end

      context "made in 5 facilities" do
        let(:order_count) { 5 }

        it { expect(subject).to eq(facilities.first(order_count)) }
      end

      context "made in more than 5 facilities" do
        let(:order_count) { 6 }

        it { expect(subject).to eq(facilities.first(limit)) }
      end
    end
  end
end
