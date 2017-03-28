require "rails_helper"

RSpec.describe SecureRooms::AccessRules::OperatorRule, type: :service do
  subject(:result) do
    described_class.call(
      card_user,
      card_reader.secure_room,
      [],
      nil,
    )
  end

  let(:card_reader) { create :card_reader }

  context "user is facility operator" do
    let(:card_user) { create :user, :facility_administrator, facility: card_reader.secure_room.facility }

    it { is_expected.to eq :ok }
  end

  context "user is not an operator" do
    let(:card_user) { create :user }

    it { is_expected.to be_nil }
  end
end
