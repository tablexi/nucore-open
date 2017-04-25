require "rails_helper"

RSpec.describe SecureRoomsApi::EventsController do
  before do
    name = Settings.secure_rooms_api.basic_auth_name
    password = Settings.secure_rooms_api.basic_auth_password
    encoded_auth_credentials = ActionController::HttpAuthentication::Basic.encode_credentials(name, password)
    request.env['HTTP_AUTHORIZATION'] = encoded_auth_credentials
  end

  describe "create" do
    subject { response }

    describe "some data" do
      let(:params) do
        {
          message_id: "000009",
          message_type: "10",
          class_code: "5",
          task_code: "5",
          event_code: "1",
          priority: "100",
          task_description: "eventlogger task",
          event_description: "start task",
        }
      end

      before do
        post :create, params
      end

      it { is_expected.to be_success }
    end

    describe "invalid credentials" do
      before do
        request.env.delete("HTTP_AUTHORIZATION")
        post :create
      end

      it { is_expected.to have_http_status(:unauthorized) }
    end
  end
end
