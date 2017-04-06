require "rails_helper"

RSpec.describe SecureRooms::AccessRules::AccountSelectionRule, type: :service do
  let(:rule) do
    described_class.new(
      card_user,
      card_reader,
      accounts: accounts,
      selected_account: selected_account,
    )
  end
  let(:card_user) { build :user }
  let(:card_reader) { build :card_reader }
  let(:selected_account) { accounts.first }

  subject(:result) { rule.call }

  context "no accounts exist" do
    let(:accounts) { [] }

    it { is_expected.to have_result_code(:deny) }
  end

  context "accounts exist" do
    let(:accounts) { build_list(:account, 3, :with_account_owner, owner: card_user) }

    context "selected account was found" do
      it { is_expected.to have_result_code(:grant) }
    end

    context "selected account is empty but accounts exist" do
      let(:selected_account) { nil }

      it { is_expected.to have_result_code(:pending) }
    end
  end
end
