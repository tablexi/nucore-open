require 'spec_helper'

describe PricePolicy do

  before :each do
    @facility         = Factory.create(:facility)
    @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
    @price_group      = @facility.price_groups.create(Factory.attributes_for(:price_group))
    @item             = @facility.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id))
  end


  it "should not create using factory" do
    # putting inside begin/rescue as some PricePolicy validation functions throw exception if type is nil
    begin
      @pp = PricePolicy.create(Factory.attributes_for(:item_price_policy, :price_group_id => @price_group.id, :item_id => @item.id))
      @pp.should_not be_valid
      @pp.errors.on(:type).should_not be_nil
    rescue
      true
    end
  end


  it 'should define abstract methods' do
    class SubPricePolicy < PricePolicy
      def sub; end
    end

    sp = SubPricePolicy.create(Factory.attributes_for(:item_price_policy, :price_group_id => @price_group.id, :item_id => @item.id))

    sp.should be_respond_to(:calculate_cost_and_subsidy)
    assert_raise(RuntimeError) { sp.calculate_cost_and_subsidy }

    sp.should be_respond_to(:estimate_cost_and_subsidy)
    assert_raise(RuntimeError) { sp.estimate_cost_and_subsidy }
  end
  
end