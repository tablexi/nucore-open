require "rails_helper"

RSpec.describe SecureRooms::AccessRules::ValidAccountRule, type: :service do
  let(:rule) do
    described_class.new(
      card_user,
      card_reader,
      accounts,
      nil,
    )
  end
  let(:card_user) { build :user }
  let(:card_reader) { build :card_reader }

  subject(:result) { rule.call }

  context "no accounts exist" do
    let(:accounts) { nil }

    it { is_expected.to have_result_code(:deny) }
  end

  context "accounts exist" do
    let(:accounts) { build_list(:account, 3, :with_account_owner, owner: card_user) }

    it { is_expected.to have_result_code(:pass) }
  end
end
