require "rails_helper"

RSpec.describe SecureRooms::CheckAccess, type: :service do
  subject(:check_access) { described_class.new(rules) }

  let(:card_reader) { build :card_reader }
  let(:card_user) { build :user }

  context "with a single deny rule" do
    let(:rules) { [SecureRooms::AccessRules::DenyAllRule] }

    it "calls the rule" do
      expect_any_instance_of(SecureRooms::AccessRules::DenyAllRule).to receive(:evaluate)
      check_access.authorize(card_user, card_reader)
    end
  end
end
