require "rails_helper"

RSpec.describe SecureRooms::AccountPresenter do
  describe ".wrap" do
    let(:accounts) { build_stubbed_list :account, 3, :with_account_owner }
    subject(:presenters) { described_class.wrap(accounts) }

    it { is_expected.to all(be_a(described_class)) }
  end

  describe "instance methods" do
    let(:account) { create :account, :with_account_owner }
    subject(:presenter) { described_class.new(account) }

    describe "#to_json" do
      subject(:parsed_json) { JSON.parse(presenter.to_json) }

      describe "keys" do
        subject(:keys) { parsed_json.keys }

        it { is_expected.to include("id") }
        it { is_expected.to include("type") }
        it { is_expected.to include("description") }
        it { is_expected.to include("account_number") }
        it { is_expected.to include("expiration_month") }
        it { is_expected.to include("expiration_year") }
        it { is_expected.to include("owner_name") }
      end
    end
  end
end
