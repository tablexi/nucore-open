require 'spec_helper'

describe Affiliate do

  it { should validate_uniqueness_of(:name) }

  it 'should maintain other as a constant' do
    Affiliate::OTHER.should == Affiliate.where(:name => 'Other').first
  end

end
