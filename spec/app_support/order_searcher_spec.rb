require 'spec_helper'

describe OrderSearcher do

  let(:searcher) { described_class.new build(:user) }

  it 'returns empty results on bad input' do
    expect(searcher.search('gobbly gook')).to eq []
  end

  it 'returns empty results on nil input' do
    expect(searcher.search(nil)).to eq []
  end

end
