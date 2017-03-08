require "rails_helper"

RSpec.describe SecureRoomsApi::ScansController do
  context "scan" do
    before do
      name = Settings.secure_rooms_api.basic_auth_name
      password = Settings.secure_rooms_api.basic_auth_password
      encoded_auth_credentials = ActionController::HttpAuthentication::Basic.encode_credentials(name, password)
      request.env['HTTP_AUTHORIZATION'] = encoded_auth_credentials

      post :scan,
           card_id: card_user.card_number,
           reader_id: card_reader.card_reader_number,
           controller_id: card_reader.control_device_number
    end

    subject { response }

    let(:card_reader) { create :card_reader }
    let(:card_user) { create :user, card_number: "123456" }

    describe "initial deny response" do
      it { is_expected.to have_http_status(:forbidden) }
    end

    describe "not found response" do
      context "when card does not exist" do
        let(:card_user) { build :user }

        it { is_expected.to have_http_status(:not_found) }
        it "is expected to contain the corresponding reason" do
          expect(response.body).to match("User")
        end
      end

      context "when card reader does not exist" do
        let(:card_reader) { build :card_reader }

        it { is_expected.to have_http_status(:not_found) }
        it "is expected to contain the corresponding reason" do
          expect(response.body).to match("CardReader")
        end
      end
    end
  end
end
