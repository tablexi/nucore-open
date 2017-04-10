require "rails_helper"

RSpec.describe SecureRooms::AccessManager, type: :service do
  subject(:access_manager) { described_class.new(verdict) }

  let(:user) { build :user }
  let(:card_reader) { build :card_reader }
  let(:accounts) { create_list(:account, 3, :with_account_owner, owner: user) }
  let(:account) { build :account }

  let(:verdict) do
    SecureRooms::AccessRules::Verdict.new(:deny, user, card_reader)
  end

  before { allow_any_instance_of(User).to receive(:accounts_for_product).and_return(accounts) }

  describe "#process" do
    before { access_manager.process }

    it "creates an Event" do
      expect(SecureRooms::Event.last).not_to be_nil
    end
  end
end
