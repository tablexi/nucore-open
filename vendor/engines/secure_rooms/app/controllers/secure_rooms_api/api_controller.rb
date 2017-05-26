module SecureRoomsApi

  class ApiController < ApplicationController

    http_basic_authenticate_with(
      name: Settings.secure_rooms_api.basic_auth_name,
      password: Settings.secure_rooms_api.basic_auth_password,
    )

    skip_before_action :verify_authenticity_token

  end

end
