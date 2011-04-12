require 'spec_helper'

describe PriceGroupProduct do

  before :each do
    @facility=Factory.create(:facility)
    @facility_account=@facility.facility_accounts.create(Factory.attributes_for(:facility_account))
    @instrument=@facility.items.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
    @price_group=Factory.create(:price_group, :facility => @facility)
  end


  it 'should require product' do
    PriceGroupProduct.new(:price_group => @price_group).should validate_presence_of :product_id
  end

  it 'should require price group' do
    PriceGroupProduct.new(:product => @instrument).should validate_presence_of :price_group_id
  end

end