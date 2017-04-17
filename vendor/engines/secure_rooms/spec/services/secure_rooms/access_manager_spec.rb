require "rails_helper"

RSpec.describe SecureRooms::AccessManager, type: :service do
  let(:user) { create :user }
  let(:card_reader) { create :card_reader }
  let(:accounts) { create_list(:account, 3, :with_account_owner, owner: user) }
  let(:account) { build :account }

  let(:verdict) do
    SecureRooms::AccessRules::Verdict.new(:deny, :no_accounts, user, card_reader)
  end

  before { allow_any_instance_of(User).to receive(:accounts_for_product).and_return(accounts) }

  # TODO: Expand coverage
  describe "#process" do
    it "creates an Event" do
      expect { described_class.process(verdict) }
        .to change(SecureRooms::Event, :count).by(1)
    end

    it "creates an Occupancy" do
      expect { described_class.process(verdict) }
        .to change(SecureRooms::Occupancy, :count).by(1)
    end
  end
end
