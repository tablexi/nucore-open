require 'spec_helper'

describe SimpleInstrumentPricePolicy do

  subject(:policy) { build :simple_instrument_price_policy }

  it { should validate_numericality_of(:usage_rate).is_greater_than_or_equal_to 0 }
  it { should_not allow_value(nil).for :usage_rate }

  %w(minimum_cost usage_subsidy cancellation_cost).each do |attr|
    it { should validate_numericality_of(attr.to_sym).is_greater_than_or_equal_to 0 }
    it { should allow_value(nil).for attr.to_sym }
  end

  %w(reservation_rate reservation_subsidy overage_rate overage_subsidy).each do |attr|
    it { should_not allow_value(5.0).for attr.to_sym }
    it { should allow_value(nil).for attr.to_sym }
  end

  it 'validates presence of usage rate if purchase is not restricted' do
    policy.stub(:restrict_purchase?).and_return false
    should validate_presence_of :usage_rate
  end

  it 'does not validate presence of usage rate if purchase is restricted' do
    policy.stub(:restrict_purchase?).and_return true
    should_not validate_presence_of :usage_rate
  end

  it 'gives an error if usage_subsidy > usage_rate' do
    expect(policy).to be_valid
    policy.usage_subsidy = 15
    policy.usage_rate = 5
    expect(policy).to_not be_valid
    expect(policy.errors[:usage_subsidy]).to be_present
  end
  
  it 'does not give an error if usage_subsidy < usage_rate' do
    expect(policy).to be_valid
    policy.usage_subsidy = 15
    policy.usage_rate = 25
    expect(policy).to be_valid
  end

end
