require 'spec_helper'

describe Affiliate do

  it 'should require name' do
    should ensure_length_of(:name).is_at_least(1)
  end

  it 'should maintain other as a constant' do
    Affiliate::OTHER.should == Affiliate.where(:name => 'Other').first
  end

end
