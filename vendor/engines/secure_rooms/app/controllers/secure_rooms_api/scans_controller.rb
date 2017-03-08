class SecureRoomsApi::ScansController < ApplicationController

  http_basic_authenticate_with(
    name: Settings.secure_rooms_api.basic_auth_name,
    password: Settings.secure_rooms_api.basic_auth_password,
  )

  rescue_from ActiveRecord::RecordNotFound, with: :report_missing_ids

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
    @card_reader = SecureRooms::CardReader.find_by!(
      card_reader_number: params[:reader_id],
      control_device_number: params[:controller_id],
    )
  end

  private

  def report_missing_ids(error)
    response_json = {
      response: "deny",
      reason: error.message,
    }

    render json: response_json, status: :not_found
  end

end
