class SecureRoomsApi::ScansController < ApplicationController

  http_basic_authenticate_with(
    name: Settings.secure_rooms_api.basic_auth_name,
    password: Settings.secure_rooms_api.basic_auth_password,
  )

  def scan
    response_json = {
      response: "deny",
      reason: "I only know how to deny right now.",
    }

    render json: response_json, status: :forbidden
  end

end
