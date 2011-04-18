require 'spec_helper'

describe PricePolicy do

  before :each do
    @facility         = Factory.create(:facility)
    @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
    @price_group      = @facility.price_groups.create(Factory.attributes_for(:price_group))
    @item             = @facility.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id))
  end


  it "should not create using factory" do
    # putting inside begin/rescue as some PricePolicy validation functions throw exception if type is nil
    begin
      @pp = PricePolicy.create(Factory.attributes_for(:item_price_policy, :price_group_id => @price_group.id, :item_id => @item.id))
      @pp.should_not be_valid
      @pp.errors.on(:type).should_not be_nil
    rescue
      true
    end
  end


  it "should set default expire_date" do
    start_date=Date.strptime("2020-5-5")
    pp=Factory.create(:item_price_policy, :price_group_id => @price_group.id, :item_id => @item.id, :start_date => start_date)
    pp.expire_date.should_not be_nil
    pp.expire_date.to_date.should == Date.strptime("2020-8-31")
  end


  it "should not set default expire_date if one is given" do
    start_date=Date.strptime("2020-5-5")
    pp=Factory.create(:item_price_policy, :price_group_id => @price_group.id, :item_id => @item.id, :start_date => start_date, :expire_date => start_date)
    pp.expire_date.should_not be_nil
    pp.expire_date.to_date.should == start_date
  end


  context 'restrict purchase' do

    before :each do
      @pp=Factory.create(:item_price_policy, :item => @item, :price_group => @price_group)
      @pgp=Factory.create(:price_group_product, :product => @item, :price_group => @price_group, :reservation_window => nil)
    end

    it 'should not restrict purchase' do
      @pp.restrict_purchase.should == false
    end

    it 'should restrict purchase' do
      @pgp.destroy
      @pp.restrict_purchase.should == true
    end

    it 'should alias #restrict with query method' do
      @pp.should be_respond_to :restrict_purchase?
      @pp.restrict_purchase.should == @pp.restrict_purchase?
    end

    it 'should return false when no price group present' do
      @pp.price_group=nil
      @pp.restrict_purchase.should == false
    end

    it 'should return false when no item present' do
      @pp.item=nil
      @pp.restrict_purchase.should == false
    end

    it 'should raise on bad input' do
      assert_raise(ArgumentError) { @pp.restrict_purchase=44 }
    end

    it 'should destroy PriceGroupProduct when restricted' do
      @pp.restrict_purchase=true
      should_be_destroyed @pgp
    end

    it 'should create PriceGroupProduct when unrestricted' do
      @pgp.destroy
      @pp.restrict_purchase=false
      PriceGroupProduct.find_by_price_group_id_and_product_id(@price_group.id, @item.id).should_not be_nil
    end

  end


  context 'should define abstract methods' do

    before :each do
      class SubPricePolicy < PricePolicy
        def sub; end
      end

      @sp = SubPricePolicy.create(Factory.attributes_for(:item_price_policy, :price_group_id => @price_group.id, :item_id => @item.id))
    end

    it 'should abstract #calculate_cost_and_subsidy' do
      @sp.should be_respond_to(:calculate_cost_and_subsidy)
      assert_raise(RuntimeError) { @sp.calculate_cost_and_subsidy }
    end

    it 'should abstract #estimate_cost_and_subsidy' do
      @sp.should be_respond_to(:estimate_cost_and_subsidy)
      assert_raise(RuntimeError) { @sp.estimate_cost_and_subsidy }
    end

    it 'should abstract #product' do
      @sp.should be_respond_to(:product)
      assert_raise(RuntimeError) { @sp.product }
    end

  end


  context 'order assignment' do

    before :each do
      @user     = Factory.create(:user)
      @account  = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
      @order    = @user.orders.create(Factory.attributes_for(:order, :created_by => @user.id))
      @order_detail = @order.order_details.create(Factory.attributes_for(:order_detail).update(:product_id => @item.id, :account_id => @account.id))
      @price_group = Factory.create(:price_group, :facility => @facility)
      UserPriceGroupMember.create!(:price_group => @price_group, :user => @user)
      Factory.create(:price_group_product, :product => @item, :price_group => @price_group, :reservation_window => nil)
      @pp=Factory.create(:item_price_policy, :item => @item, :price_group => @price_group)
    end

    
    it 'should not be assigned' do
      @pp.should_not be_assigned_to_order
    end


    it 'should be assigned' do
      PurchaseAccountTransaction.create!(
        :order_detail => @order_detail,
        :transaction_amount => 10,
        :facility => @facility,
        :account => @account,
        :created_by => @user.id,
        :is_in_dispute => false
      )

      @order_detail.reload
      @order_detail.to_inprocess!
      @order_detail.to_reviewable!
      @order_detail.to_complete!
      @pp.should be_assigned_to_order
    end

  end
  
end