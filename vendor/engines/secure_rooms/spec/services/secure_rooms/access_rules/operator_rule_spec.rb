require "rails_helper"

RSpec.describe SecureRooms::AccessRules::OperatorRule, type: :service do
  let(:result) do
    described_class.call(
      card_user,
      card_reader.secure_room,
      [],
      nil,
    )
  end
  let(:card_reader) { create :card_reader }

  subject(:response) { result }

  context "user is facility operator" do
    let(:card_user) { create :user, :facility_administrator, facility: card_reader.secure_room.facility }

    it { is_expected.to have_status(:ok) }
  end

  context "user is not an operator" do
    let(:card_user) { create :user }

    it { is_expected.to be_pass }
  end
end
