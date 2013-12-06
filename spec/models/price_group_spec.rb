require 'spec_helper'

describe PriceGroup do

  before :each do
    @facility     = FactoryGirl.create(:facility)
    @price_group  = @facility.price_groups.create(FactoryGirl.attributes_for(:price_group))
  end


  it "should create using factory" do
    @price_group.should be_valid
  end

  it "should require name" do
    should validate_presence_of(:name)
  end

  it "should require unique name within a facility" do
    @price_group2 = @facility.price_groups.build(FactoryGirl.attributes_for(:price_group).update(:name => @price_group.name))
    @price_group2.should_not be_valid
    @price_group2.errors[:name].should_not be_nil
  end


  context 'can_purchase?' do

    before :each do
      @facility_account=@facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
      @product=@facility.items.create(FactoryGirl.attributes_for(:item, :facility_account_id => @facility_account.id))
    end

    it 'should not be able to purchase product' do
      @price_group.should_not be_can_purchase @product
    end

    it 'should be able to purchase product' do
      PriceGroupProduct.create!(:price_group => @price_group, :product => @product)
      @price_group.should be_can_purchase @product
    end

  end

  describe 'can_delete?' do
    it 'should not be deletable if global' do
      @global_price_group = FactoryGirl.build(:price_group, facility: nil)
      @global_price_group.save(:validate => false)
      @global_price_group.should be_persisted
      @global_price_group.should_not be_can_delete
      @global_price_group.destroy
      # lambda { @global_price_group.destroy }.should raise_error ActiveRecord::DeleteRestrictionError
      @global_price_group.should_not be_destroyed
    end

    it 'should be deletable if no price policies' do
      @price_group.should be_can_delete
      @price_group.destroy
      @price_group.should be_destroyed
    end

    context 'with price policy' do
      before :each do
        @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
        @item = @facility.items.create(FactoryGirl.attributes_for(:item, :facility_account_id => @facility_account.id))
        @price_policy = @item.item_price_policies.create(FactoryGirl.attributes_for(:item_price_policy, :price_group => @price_group))
      end

      it 'should be deletable if no orders on policy' do
        @price_group.should be_can_delete
        @price_group.destroy
        @price_group.should be_destroyed
      end

      it 'should not be deletable if there are orders on a policy' do
        @user = FactoryGirl.create(:user)
        @order = FactoryGirl.create(:order, :user => @user, :created_by => @user.id )
        @order_detail = @order.order_details.create(FactoryGirl.attributes_for(:order_detail, :product => @item, :price_policy => @price_policy))
        @order_detail.reload.price_policy.should == @price_policy
        @price_group.should_not be_can_delete
        lambda { @price_group.destroy }.should raise_error ActiveRecord::DeleteRestrictionError
        @price_group.should_not be_destroyed
      end
    end
  end


  # global price groups are special cases; we don't test them here because price groups are required to have facilities
  # it "should not be deletable if its a global price group" do
  #   @global_price_group = FactoryGirl.create(:price_group)
  #   @global_price_group.should be_valid
  #   @global_price_group.destroy.should == false
  # end

end
