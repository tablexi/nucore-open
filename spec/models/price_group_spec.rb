require 'spec_helper'

describe PriceGroup do

  it "should create using factory" do
    @facility     = Factory.create(:facility)
    @price_group  = @facility.price_groups.create(Factory.attributes_for(:price_group))
    @price_group.should be_valid
  end

  it "should require name" do
    should validate_presence_of(:name)
  end

  it "should require unique name within a facility" do
    @facility     = Factory.create(:facility)
    @price_group1 = @facility.price_groups.create(Factory.attributes_for(:price_group))
    @price_group2 = @facility.price_groups.build(Factory.attributes_for(:price_group).update(:name => @price_group1.name))
    @price_group2.should_not be_valid
    @price_group2.errors.on(:name).should_not be_nil
  end

  # global price groups are special cases; we don't test them here because price groups are required to have facilities
  # it "should not be deletable if its a global price group" do
  #   @global_price_group = Factory.create(:price_group)
  #   @global_price_group.should be_valid
  #   @global_price_group.destroy.should == false
  # end

end
