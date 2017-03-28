require "rails_helper"

RSpec.describe SecureRooms::AccessRules::MultipleAccountsRule, type: :service do
  subject(:result) do
    described_class.call(
      card_user,
      card_reader.secure_room,
      accounts,
      nil,
    )
  end

  let(:card_user) { create :user }
  let(:card_reader) { create :card_reader }

  context "user has accounts for this product" do
    let(:accounts) { create_list(:account, 3, :with_account_owner, owner: card_user) }

    it { is_expected.to eq :multiple_choices }
  end

  context "no possible accounts exist" do
    let(:accounts) { nil }

    it { is_expected.to be_nil }
  end
end
