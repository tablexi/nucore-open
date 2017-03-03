require "rails_helper"

RSpec.describe SecureRoomsApi::ScansController do
  context "scan" do
    before do
      name = Settings.secure_rooms_api.basic_auth_name
      password = Settings.secure_rooms_api.basic_auth_password
      encoded_auth_credentials = ActionController::HttpAuthentication::Basic.encode_credentials(name, password)
      request.env['HTTP_AUTHORIZATION'] = encoded_auth_credentials
      post :scan
    end

    it "denies entry until we add logic" do
      expect(response).to have_http_status(:forbidden)
    end
  end
end
