require "rails_helper"

RSpec.describe SecureRooms::AccessManager, type: :service do
  subject(:access_manager) { described_class.new(user, card_reader, account) }

  let(:user) { build :user }
  let(:card_reader) { build :card_reader }
  let(:accounts) { create_list(:account, 3, :with_account_owner, owner: user) }
  let(:account) { build :account }

  before { allow_any_instance_of(User).to receive(:accounts_for_product).and_return(accounts) }

  describe "#process" do
    before { access_manager.process }

    it "generates a verdict" do
      expect(access_manager.verdict).not_to be_nil
    end

    it "creates an Event" do
      expect(SecureRooms::Event.last).not_to be_nil
    end
  end
end
