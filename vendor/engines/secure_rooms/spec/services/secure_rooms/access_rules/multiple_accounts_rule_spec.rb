require "rails_helper"

RSpec.describe SecureRooms::AccessRules::MultipleAccountsRule, type: :service do
  let(:result) do
    described_class.call(
      card_user,
      card_reader.secure_room,
      accounts,
      nil,
    )
  end
  let(:card_user) { build :user }
  let(:card_reader) { build :card_reader }

  subject(:response) { result }

  context "user has accounts for this product" do
    let(:accounts) { build_list(:account, 3, :with_account_owner, owner: card_user) }

    it { is_expected.to have_status(:multiple_choices) }
  end

  context "no possible accounts exist" do
    let(:accounts) { nil }

    it { is_expected.to be_pass }
  end
end
