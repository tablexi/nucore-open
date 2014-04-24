require 'spec_helper'

describe OrderSearcher do

  let(:searcher) { described_class.new build(:user) }

  it 'returns empty results on bad input' do
    expect(searcher.search('gobbly gook')).to eq []
  end

  it 'returns empty results on nil input' do
    expect(searcher.search(nil)).to eq []
  end

  it 'searches externally when lowercase prefix is given' do
    query = 'cx-36'
    expect(searcher).to receive(:search_external).with(query).and_call_original
    expect(searcher).to receive :insensitive_where
    searcher.search query
  end

end
