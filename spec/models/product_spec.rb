require 'spec_helper'

describe Product do
  it "should not create using factory" do
    @facility         = Factory.create(:facility)
    @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
    @product          = Product.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id))

    @product.errors.on(:type).should_not be_nil
  end

  it "should return all current price policies"
end
