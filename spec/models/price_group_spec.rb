require 'spec_helper'

describe PriceGroup do

  before :each do
    @facility     = Factory.create(:facility)
    @price_group  = @facility.price_groups.create(Factory.attributes_for(:price_group))
  end


  it "should create using factory" do
    @price_group.should be_valid
  end

  it "should require name" do
    should validate_presence_of(:name)
  end

  it "should require unique name within a facility" do
    @price_group2 = @facility.price_groups.build(Factory.attributes_for(:price_group).update(:name => @price_group.name))
    @price_group2.should_not be_valid
    @price_group2.errors[:name].should_not be_nil
  end


  context 'can_purchase?' do

    before :each do
      @facility_account=@facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @product=@facility.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id))
    end

    it 'should not be able to purchase product' do
      @price_group.should_not be_can_purchase @product
    end

    it 'should be able to purchase product' do
      PriceGroupProduct.create!(:price_group => @price_group, :product => @product)
      @price_group.should be_can_purchase @product
    end

  end

  # global price groups are special cases; we don't test them here because price groups are required to have facilities
  # it "should not be deletable if its a global price group" do
  #   @global_price_group = Factory.create(:price_group)
  #   @global_price_group.should be_valid
  #   @global_price_group.destroy.should == false
  # end

end
