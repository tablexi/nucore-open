require "rails_helper"

RSpec.describe SecureRoomsApi::EventsController do
  before do
    name = Settings.secure_rooms_api.basic_auth_name
    password = Settings.secure_rooms_api.basic_auth_password
    encoded_auth_credentials = ActionController::HttpAuthentication::Basic.encode_credentials(name, password)
    request.env['HTTP_AUTHORIZATION'] = encoded_auth_credentials
  end

  describe "create" do
    context "with some data" do
      let(:params) do
        {
          message_id: "000009",
          message_type: "10",
          message_time: "03:25:26 GMT 01/22/2000",
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

      describe "response" do
        subject { response }

        it { is_expected.to be_success }
      end

      describe "new alert" do
        subject(:alert) { SecureRooms::Alert.find_by(message_id: params[:message_id]) }

        it "stores a parsed timestamp properly" do
          m_t = DateTime.strptime(params[:message_time], "%H:%M:%S %Z %m/%d/%Y")
          expect(alert.message_time).to eq m_t
        end

        it "stores all values" do
          expect(alert.message_id).to eq params[:message_id]
          expect(alert.message_type).to eq params[:message_type]
          expect(alert.class_code).to eq params[:class_code]
          expect(alert.task_code).to eq params[:task_code]
          expect(alert.event_code).to eq params[:event_code]
          expect(alert.priority).to eq params[:priority]
          expect(alert.task_description).to eq params[:task_description]
          expect(alert.event_description).to eq params[:event_description]
        end
      end
    end

    context "with invalid credentials" do
      before do
        request.env.delete("HTTP_AUTHORIZATION")
        post :create
      end

      describe "response" do
        subject { response }

        it { is_expected.to have_http_status(:unauthorized) }
      end
    end
  end
end
