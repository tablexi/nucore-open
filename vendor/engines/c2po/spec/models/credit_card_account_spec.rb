# frozen_string_literal: true

require "rails_helper"

RSpec.describe CreditCardAccount do

  let(:facility) { FactoryBot.create(:facility) }
  subject(:account) { FactoryBot.create(:credit_card_account, :with_account_owner, facility: facility) }

  include_examples "AffiliateAccount"
  include_examples "an Account"

  it "should be limited to a single facility" do
    expect(described_class).to be_single_facility
  end

  it "has the facility association" do
    expect(account.facility).to eq facility
  end

end
