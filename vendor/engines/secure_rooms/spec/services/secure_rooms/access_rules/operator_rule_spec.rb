require "rails_helper"

RSpec.describe SecureRooms::AccessRules::OperatorRule, type: :service do
  let(:rule) do
    described_class.new(
      card_user,
      card_reader,
    )
  end
  let(:card_reader) { build :card_reader }

  subject(:response) { rule.call }

  context "user is facility operator" do
    let(:card_user) { create :user, :facility_administrator, facility: card_reader.secure_room.facility }

    it { is_expected.to have_result_code(:grant) }
  end

  context "user is a global admin" do
    let(:card_user) { create :user, :administrator }

    it { is_expected.to have_result_code(:pass) }
  end

  context "user is not an operator" do
    let(:card_user) { create :user }

    it { is_expected.to have_result_code(:pass) }
  end
end
