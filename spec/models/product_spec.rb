require 'spec_helper'

describe Product do

  before :each do
    @facility         = Factory.create(:facility)
    @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
  end

  it "should not create using factory" do
    @product = Product.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id))
    @product.errors[:type].should_not be_nil
  end

  context 'with item' do

    before :each do
      @item = @facility.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id))
    end

    it "should create map to default price groups" do
      PriceGroupProduct.count.should == PriceGroup.globals.count
      PriceGroupProduct.find_by_product_id_and_price_group_id(@item.id, PriceGroup.base.first.id).should_not be_nil
      PriceGroupProduct.find_by_product_id_and_price_group_id(@item.id, PriceGroup.external.first.id).should_not be_nil
    end

    it 'should give correct initial order status' do
      os=OrderStatus.inprocess.first
      @item.update_attribute(:initial_order_status_id, os.id)
      @item.initial_order_status.should == os
    end

    it 'should give default order status if status not set' do
      Item.new.initial_order_status.should == OrderStatus.default_order_status
    end

  end

  context 'current_price_policies' do
    it "should return all current price policies"
  end

  context 'can_purchase?' do
    class TestProduct < Product
      def account_required
        false
      end
    end
    class TestPricePolicy < PricePolicy
    end
    before :each do
      @product = TestProduct.create!(:facility => @facility, :name => 'Test Product', :url_name => 'test')
      @price_group = Factory.create(:price_group, :facility => @facility)
      @price_group2 = Factory.create(:price_group, :facility => @facility)
      @user = Factory.create(:user)
      Factory.create(:user_price_group_member, :user => @user, :price_group => @price_group)
      @user.reload

      @user_price_policy_ids = @user.price_groups.map(&:id)
    end
    it 'should not be purchasable if it is archived' do
      @product.update_attributes :is_archived => true
      @product.should_not be_available_for_purchase
    end

    it 'should not be purchasable if the facility is inactive' do
      @product.facility.update_attributes :is_active => false
      @product.should_not be_available_for_purchase
    end

    it 'should not be purchasable if you pass it empty groups' do
      @product.should_not be_can_purchase([])
    end
    
    it "should not be purchasable if there are no pricing rules ever" do
      @product.should_not be_can_purchase(@user_price_policy_ids)
    end

    it "should not be purchasable if there is no price rule for a user, but there are current price rules" do
      @price_policy = TestPricePolicy.create!(:price_group => @price_group2, 
                                              :product => @product, 
                                              :start_date => Time.zone.now - 1.day, 
                                              :expire_date => Time.zone.now + 7.days,
                                              :can_purchase => true)
      @product.should_not be_can_purchase(@user_price_policy_ids)
    end

    it "should be purchasable if there is a current price rule for the user's group" do
      @price_policy = TestPricePolicy.create!(:price_group => @price_group, 
                                              :product => @product, 
                                              :start_date => Time.zone.now - 1.day, 
                                              :expire_date => Time.zone.now + 7.days,
                                              :can_purchase => true)
      @product.should be_can_purchase(@user_price_policy_ids)
    end
    
    it "should be purchasable if the user has an expired price rule where they were allowed to purchase" do
      @price_policy = TestPricePolicy.create!(:price_group => @price_group, 
                                              :product => @product, 
                                              :start_date => Time.zone.now - 7.days, 
                                              :expire_date => Time.zone.now - 1.day,
                                              :can_purchase => true)
      @product.should be_can_purchase(@user_price_policy_ids)
    end

    it "should not be purchasable if there is a current rule, but marked as can_purchase = false" do
      @price_policy = TestPricePolicy.create!(:price_group => @price_group, 
                                              :product => @product, 
                                              :start_date => Time.zone.now - 1.day, 
                                              :expire_date => Time.zone.now + 7.days,
                                              :can_purchase => false)
      @product.should_not be_can_purchase(@user_price_policy_ids)
    end
    
    it 'should not be purchasable if the most recent expired policy is marked can_purchase = false' do
      @price_policy = TestPricePolicy.create!(:price_group => @price_group, 
                                              :product => @product, 
                                              :start_date => Time.zone.now - 7.day, 
                                              :expire_date => Time.zone.now - 6.days,
                                              :can_purchase => true)
      @price_policy2 = TestPricePolicy.create!(:price_group => @price_group, 
                                              :product => @product, 
                                              :start_date => Time.zone.now - 5.day, 
                                              :expire_date => Time.zone.now + 4.days,
                                              :can_purchase => false)
      @product.should_not be_can_purchase(@user_price_policy_ids)
    end

    it 'should be purchasable if the most recent expired policy is can_purchase, but old ones arent' do
      @price_policy = TestPricePolicy.create!(:price_group => @price_group, 
                                              :product => @product, 
                                              :start_date => Time.zone.now - 7.day, 
                                              :expire_date => Time.zone.now - 6.days,
                                              :can_purchase => false)
      @price_policy2 = TestPricePolicy.create!(:price_group => @price_group, 
                                              :product => @product, 
                                              :start_date => Time.zone.now - 5.day, 
                                              :expire_date => Time.zone.now + 4.days,
                                              :can_purchase => true)
      @product.should be_can_purchase(@user_price_policy_ids)
    end

  end
end
