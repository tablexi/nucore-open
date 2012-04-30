require 'spec_helper'
require 'active_support/secure_random'

describe Account do

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

    it "should return error if the product's account is not open for a chart string" do
      @nufs_account.validate_against_product(@item, @user).should_not be_nil
    end

    context 'bundles' do
      before :each do
        @item2 = @facility.items.create(Factory.attributes_for(:item, :account => 78960, :facility_account_id => @facility_account.id))
        @bundle = @facility.bundles.create(Factory.attributes_for(:bundle, :facility_account_id => @facility_account.id))
        [ @item, @item2 ].each{|item| BundleProduct.create!(:quantity => 1, :product => item, :bundle => @bundle) }
      end

      it "should return error if the product is a bundle and one of the bundled product's account is not open for a chart string" do
        cs='191-5401900-60006385-01-1059-1095' # a grant chart string
        define_open_account(NUCore::COMMON_ACCOUNT, cs) # define the string so it is valid on NufsAccount#validate
        @nufs_account.account_number=cs
        assert @nufs_account.save
        define_open_account(@item.account, cs) # only one product of the bundle should be open
        @nufs_account.validate_against_product(@bundle, @user).should_not be_nil
      end
    end

  end
end
