require 'spec_helper'

describe InstrumentRestrictionLevel do
  before :each do
    @facility         = Factory.create(:facility)
    @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
    @instrument       = @facility.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
    @restriction_levels = []
    3.times do
      @restriction_levels << Factory.create(:instrument_restriction_level, :instrument_id => @instrument.id)
    end
    @restriction_level = @restriction_levels[0]
  end
  it { should validate_presence_of :name }
  it { should validate_presence_of :instrument }
  it { should validate_uniqueness_of(:name).scoped_to(:instrument_id) }
  
  it "removing the level should also remove the join to the scheduling rule" do
    @rule = @instrument.schedule_rules.create(Factory.attributes_for(:schedule_rule))
    @rule.instrument_restriction_levels << @restriction_level
    
    @rule.instrument_restriction_levels.size.should == 1
    
    @restriction_level.destroy
    @rule.reload
    @rule.instrument_restriction_levels.should be_empty
  end
  
  it "should nullify the product users's instrument restrcition when it's deleted" do
    @user = Factory.create(:user)
    @product_user = ProductUser.create(:product => @instrument, :user => @user, :approved_by => @user.id, :instrument_restriction_level => @restriction_level)
    @product_user.instrument_restriction_level_id.should == @restriction_level.id
    @restriction_level.destroy
    @product_user.reload
    @product_user.instrument_restriction_level_id.should be_nil
  end
end