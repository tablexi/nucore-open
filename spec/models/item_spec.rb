require 'spec_helper'
require 'product_shared_examples'

describe Item do
  it "should create using factory" do
    @facility         = Factory.create(:facility)
    @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
    @item             = @facility.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id))
    @item.should be_valid
    @item.type.should == 'Item'
  end

  it_should_behave_like "NonReservationProduct", :item

end
