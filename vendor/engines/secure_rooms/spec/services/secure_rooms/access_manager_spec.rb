require "rails_helper"

RSpec.describe SecureRooms::AccessManager, type: :service do
  let(:user) { create :user }
  let(:card_reader) { create :card_reader }

  let(:verdict) do
    SecureRooms::AccessRules::Verdict.new(:deny, :no_accounts, user, card_reader)
  end

  describe "#process" do
    it "calls each AccessHandler" do
      expect(SecureRooms::AccessHandlers::EventHandler).to receive(:process)
      expect(SecureRooms::AccessHandlers::OccupancyHandler).to receive(:process)

      described_class.process(verdict)
    end
  end
end
