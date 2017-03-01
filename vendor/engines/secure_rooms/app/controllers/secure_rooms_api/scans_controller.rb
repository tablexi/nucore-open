class SecureRoomsApi::ScansController < ApplicationController

  http_basic_authenticate_with(
    name: Settings.secure_rooms_api.basic_auth_name,
    password: Settings.secure_rooms_api.basic_auth_password,
  )

  before_action :load_models

  def scan
    response_json = {
      response: "deny",
      reason: "I only know how to deny right now.",
    }

    render json: response_json, status: :forbidden
  end

  def load_models
    @user = User.find_by!(card_number: params[:card_id])
    @control_device = ControlDevice.find(params[:controller_id])
    @card_reader = CardReader.find(params[:reader_id])
  end

end
