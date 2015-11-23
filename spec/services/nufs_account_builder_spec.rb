require "rails_helper"

RSpec.describe NufsAccountBuilder, type: :service do
  let(:builder) { described_class.new(options) }

  it "is an AccountBuilder" do
    expect(described_class).to be <= AccountBuilder
  end

  describe "#build override" do
    let(:options) do
      {
        account_type: "NufsAccount",
        facility: build_stubbed(:facility),
        owner_user: build_stubbed(:user),
        current_user: build_stubbed(:user),
        params: params,
      }
    end

    let(:params) do
      ActionController::Parameters.new(
        nufs_account: {
          account_number: "1234",
          description: "foobar",
        }
      )
    end

    it "sets expired_at" do
      expect(builder.build.expires_at).to be_present
    end
  end
end
