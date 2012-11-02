require 'spec_helper'

describe Affiliate do

  it { should validate_uniqueness_of(:name) }

  it { should validate_presence_of(:name) }

  it 'should maintain other as a constant' do
    Affiliate.OTHER.should == Affiliate.where(:name => 'Other').first
  end

  it 'should not allow OTHER to be destroyed' do
    Affiliate.OTHER.destroy
    Affiliate.OTHER.should_not be_destroyed
  end

  it 'should allow non-OTHER affiliates to be destroyed' do
    affiliate=Affiliate.create!(:name => 'aff1')
    affiliate.destroy
    affiliate.should be_destroyed
  end

end
