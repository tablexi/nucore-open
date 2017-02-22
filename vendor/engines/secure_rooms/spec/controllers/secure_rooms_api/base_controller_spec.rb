require "rails_helper"

RSpec.describe SecureRoomsApi::BaseController do
  context "scan" do
    before do
      encoded_auth_credentials = ActionController::HttpAuthentication::Basic.encode_credentials('dan', 'hodos')
      request.env['HTTP_AUTHORIZATION'] = encoded_auth_credentials
      post :scan
    end

    it 'denies entry until we add logic' do
      expect(response).to be_ok
    end
  end
end

