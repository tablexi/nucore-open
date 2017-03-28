require "rails_helper"

RSpec.describe SecureRooms::CheckAccess, type: :service do
  subject(:check_access) { described_class.new(rules) }

  let(:card_reader) { create :card_reader }
  let(:card_user) { create :user, card_number: "123456" }

  context "with a single deny rule" do
    let(:rules) { [SecureRooms::AccessRules::DefaultRestrictionRule] }

    it "calls the rule" do
      expect(SecureRooms::AccessRules::DefaultRestrictionRule).to receive(:call)
      check_access.authorize(card_user, card_reader)
    end
  end
end
