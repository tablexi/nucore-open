require "rails_helper"
require "action_controller/parameters"
require_relative "../engine_helper"

RSpec.describe SplitAccounts::SplitAccountBuilder, type: :service, split_accounts: true do
  let(:builder) { described_class.new(options) }

  it "is an AccountBuilder" do
    expect(described_class).to be <= AccountBuilder
  end

  describe "#build" do
    let(:options) do
      {
        account_type: "SplitAccounts::SplitAccount",
        facility: build_stubbed(:facility),
        owner_user: build_stubbed(:user),
        current_user: build_stubbed(:user),
        params: params,
      }
    end

    let(:params) do
      ActionController::Parameters.new({
        split_accounts_split_account: {
          splits_attributes: {
            "0" => {
              subaccount_id: subaccount_2.id,
              percent: 50,
              extra_penny: true
            },
            "1" => {
              subaccount_id: subaccount_1.id,
              percent: 50,
              extra_penny: false
            },
          }
        }
      })
    end

    let(:subaccount_1) { create(:setup_account, expires_at: (Time.zone.now + 1.month).change(usec: 0)) }
    let(:subaccount_2) { create(:setup_account, expires_at: (Time.zone.now + 1.month).change(usec: 0)) }

    it "sets splits" do
      expect(builder.build.splits.size).to be(2)
    end

    it "sets expired_at to earliest expiring subaccount" do
      expect(builder.build.expires_at).to eq(subaccount_1.expires_at)
    end
  end

end
