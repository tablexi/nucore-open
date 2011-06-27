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

  it "should create map to default price groups" do
    item = @facility.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id))
    PriceGroupProduct.count.should == 2
    PriceGroupProduct.find_by_product_id_and_price_group_id(item.id, PriceGroup.northwestern.first.id).should_not be_nil
    PriceGroupProduct.find_by_product_id_and_price_group_id(item.id, PriceGroup.external.first.id).should_not be_nil
  end

  it "should return all current price policies"
end
