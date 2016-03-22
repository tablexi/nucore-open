require "rails_helper"

RSpec.describe PriceGroupProduct do

  before :each do
    @facility = FactoryGirl.create(:facility)
    @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
    @instrument = FactoryGirl.create(:instrument,
                                     facility: @facility,
                                     facility_account_id: @facility_account.id)
    @price_group = FactoryGirl.create(:price_group, facility: @facility)
  end

  it "should require product" do
    expect(PriceGroupProduct.new(price_group: @price_group)).to validate_presence_of :product_id
  end

  it "should require price group" do
    expect(PriceGroupProduct.new(product: @instrument)).to validate_presence_of :price_group_id
  end

  it "should require reservation window" do
    expect(PriceGroupProduct.new(product: @instrument, price_group: @price_group)).to validate_presence_of :reservation_window
  end

  it "should not require reservation window" do
    item = @facility.items.create(FactoryGirl.attributes_for(:item, facility_account_id: @facility_account.id))
    expect(PriceGroupProduct.new(product: item, price_group: @price_group)).not_to validate_presence_of :reservation_window
  end

end
