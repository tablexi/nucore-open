require "rails_helper"

RSpec.describe SecureRooms::AccessManager, type: :service do
  let(:user) { build :user }
  let(:card_reader) { build :card_reader }
  let(:accounts) { create_list(:account, 3, :with_account_owner, owner: user) }
  let(:account) { build :account }

  let(:verdict) do
    SecureRooms::AccessRules::Verdict.new(:deny, user, card_reader)
  end

  before { allow_any_instance_of(User).to receive(:accounts_for_product).and_return(accounts) }

  describe "#process" do
    it "creates an Event" do
      expect { described_class.process(verdict) }
        .to change(SecureRooms::Event, :count).by(1)
    end
  end
end
