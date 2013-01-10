require 'spec_helper'
require 'product_shared_examples'

describe Item do
  it "should create using factory" do
    @facility         = FactoryGirl.create(:facility)
    @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
    @item             = @facility.items.create(FactoryGirl.attributes_for(:item, :facility_account_id => @facility_account.id))
    @item.should be_valid
    @item.type.should == 'Item'
  end

  it_should_behave_like "NonReservationProduct", :item

end
