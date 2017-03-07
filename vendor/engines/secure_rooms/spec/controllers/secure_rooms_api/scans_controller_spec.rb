require "rails_helper"

RSpec.describe SecureRoomsApi::ScansController do
  context "scan" do
    before do
      name = Settings.secure_rooms_api.basic_auth_name
      password = Settings.secure_rooms_api.basic_auth_password
      encoded_auth_credentials = ActionController::HttpAuthentication::Basic.encode_credentials(name, password)
      request.env['HTTP_AUTHORIZATION'] = encoded_auth_credentials

      post :scan,
           card_id: card_number,
           controller_id: control_device_id,
           reader_id: card_reader_id
    end

    subject { response }

    let(:card_reader) { create :card_reader }
    let(:card_user) { create :user, card_number: '123456' }

    let(:card_reader_id) { card_reader.id }
    let(:control_device_id) { card_reader.control_device.id }
    let(:card_number) { card_user.card_number }

    describe "initial deny response" do
      it { is_expected.to have_http_status(:forbidden) }
    end

    describe "not found response" do
      subject { response }

      context "when card does not exist" do
        let(:card_number) { nil }

        it { is_expected.to have_http_status(:not_found) }
        it "is expected to contain the corresponding reason" do
          expect(response.body).to match("Couldn't find User")
        end
      end

      context "when card reader does not exist" do
        let(:card_reader_id) { nil }

        it { is_expected.to have_http_status(:not_found) }
        it "is expected to contain the corresponding reason" do
          expect(response.body).to match("Couldn't find SecureRooms::CardReader")
        end
      end

      context "when control device does not exist" do
        let(:control_device_id) { nil }

        it { is_expected.to have_http_status(:not_found) }
        it "is expected to contain the corresponding reason" do
          expect(response.body).to match("Couldn't find SecureRooms::ControlDevice")
        end
      end
    end
  end
end
