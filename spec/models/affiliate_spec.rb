require "rails_helper"

RSpec.describe Affiliate do

  it { is_expected.to validate_uniqueness_of(:name) }

  it { is_expected.to validate_presence_of(:name) }

  it 'should maintain other as a constant' do
    expect(Affiliate.OTHER).to eq(Affiliate.where(:name => 'Other').first)
  end

  it 'should not allow OTHER to be destroyed' do
    Affiliate.OTHER.destroy
    expect(Affiliate.OTHER).not_to be_destroyed
  end

  it 'should allow non-OTHER affiliates to be destroyed' do
    affiliate=Affiliate.create!(:name => 'aff1')
    affiliate.destroy
    expect(affiliate).to be_destroyed
  end

end
