# These shared examples require a `let(:account)`

RSpec.shared_examples_for "AffiliateAccount" do

  let(:affiliate) { FactoryBot.create(:affiliate) }
  it { is_expected.to validate_presence_of(:affiliate_id) }

  it "requires affiliate_other if affiliate is 'Other'" do
    account.affiliate = Affiliate.OTHER
    account.affiliate_other = nil
    expect(account).to be_invalid
    expect(account)
      .to validate_length_of(:affiliate_other).is_at_least(1)
  end

  it "does not require affiliate_other if affiliate is not 'Other'" do
    account.affiliate = affiliate
    account.affiliate_other = nil
    expect(account.affiliate).to be_present
    expect(account.affiliate).not_to be_other
    account.valid?
    expect(account)
      .not_to validate_length_of(:affiliate_other).is_at_least(1)
  end

end
