require "rails_helper"

RSpec.describe SecureRooms::AccessHandlers::EventHandler, type: :service do
  let(:user) { create :user }
  let(:card_reader) { create :card_reader }

  let(:verdict) do
    SecureRooms::AccessRules::Verdict.new(:deny, :no_accounts, user, card_reader)
  end

  # TODO: Expand coverage
  describe "#process" do
    it "creates an Event" do
      expect { described_class.process(verdict) }
        .to change(SecureRooms::Event, :count).by(1)
    end
  end
end
