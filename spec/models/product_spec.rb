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
      PriceGroupProduct.count.should == 2
      PriceGroupProduct.find_by_product_id_and_price_group_id(@item.id, PriceGroup.northwestern.first.id).should_not be_nil
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

  it "should return all current price policies"
end
