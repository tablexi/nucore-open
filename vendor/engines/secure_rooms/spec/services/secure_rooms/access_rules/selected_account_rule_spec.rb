require "rails_helper"

RSpec.describe SecureRooms::AccessRules::SelectedAccountRule, type: :service do
  let(:result) do
    described_class.call(
      card_user,
      card_reader.secure_room,
      accounts,
      selected_account,
    )
  end
  let(:card_user) { build :user }
  let(:card_reader) { build :card_reader }
  let(:accounts) { build_list(:account, 3, :with_account_owner, owner: card_user) }

  subject(:response) { result }

  context "selected account was found" do
    let(:selected_account) { accounts.first }

    it { is_expected.to have_status(:ok) }
  end

  context "selected account is empty" do
    let(:selected_account) { nil }

    it { is_expected.to be_pass }
  end
end
