require 'spec_helper'

describe ProductAccessGroup do
  before :each do
    @facility         = FactoryGirl.create(:facility)
    @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
    @instrument = @product = @facility.instruments.create(FactoryGirl.attributes_for(:instrument, :facility_account_id => @facility_account.id))
    @restriction_levels = []
    3.times do
      @restriction_levels << FactoryGirl.create(:product_access_group, :product_id => @product.id)
    end
    @restriction_level = @restriction_levels[0]
  end
  it { should validate_presence_of :name }
  it { should validate_presence_of :product }
  it { should validate_uniqueness_of(:name).scoped_to(:product_id) }
  
  it "removing the level should also remove the join to the scheduling rule" do
    @rule = @instrument.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule))
    @rule.product_access_groups << @restriction_level
    
    @rule.product_access_groups.size.should == 1
    
    @restriction_level.destroy
    @rule.reload
    @rule.product_access_groups.should be_empty
  end
  
  it "should nullify the product users's instrument restrcition when it's deleted" do
    @user = FactoryGirl.create(:user)
    @product_user = ProductUser.create(:product => @instrument, :user => @user, :approved_by => @user.id, :product_access_group => @restriction_level)
    @product_user.product_access_group_id.should == @restriction_level.id
    @restriction_level.destroy
    @product_user.reload
    @product_user.product_access_group_id.should be_nil
  end
end