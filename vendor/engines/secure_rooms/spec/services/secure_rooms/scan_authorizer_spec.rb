require "rails_helper"

RSpec.describe SecureRooms::ScanAuthorizer, type: :service do
  subject(:scan_authorizer) do
    described_class.new(
      card_user.card_number,
      card_reader.card_reader_number,
      card_reader.control_device_number,
    )
  end
  let(:card_reader) { create :card_reader }
  let(:card_user) { create :user, card_number: "123456" }

  describe "negative responses" do
    subject(:response) { scan_authorizer.response }
    before { scan_authorizer.perform }

    describe "initial deny response" do
      it "includes the status" do
        expect(response[:status]).to eq :forbidden
      end

      it "includes the response key" do
        expect(response[:json][:response]).to eq "deny"
      end
    end

    describe "not found response" do
      context "when card does not exist" do
        let(:card_user) { build :user }

        it "includes the status" do
          expect(response[:status]).to eq :not_found
        end

        it "includes the response key" do
          expect(response[:json][:response]).to eq "deny"
        end

        it "includes the reason" do
          expect(response[:json].to_json).to match("User")
        end
      end

      context "when card reader does not exist" do
        let(:card_reader) { build :card_reader }

        it "includes the status" do
          expect(response[:status]).to eq :not_found
        end

        it "includes the response key" do
          expect(response[:json][:response]).to eq "deny"
        end

        it "includes the reason" do
          expect(response[:json].to_json).to match("CardReader")
        end
      end
    end

    describe "positive responses" do
      context "with multiple accounts" do
        subject(:response) { scan_authorizer.response }
        before do
          accounts = create_list(:account, 3, :with_account_owner, owner: card_user)
          allow(scan_authorizer).to receive(:user_accounts).and_return(accounts)

          scan_authorizer.perform
        end

        it "includes the status" do
          expect(response[:status]).to eq :multiple_choices
        end
        it "is expected to contain a list of accounts" do
          expect(response[:json]).to include(:accounts)
          expect(response[:json][:accounts].size).to eq 3
        end
      end
    end
  end
end
