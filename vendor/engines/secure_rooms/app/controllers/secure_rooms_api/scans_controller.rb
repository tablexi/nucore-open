class SecureRoomsApi::ScansController < ApplicationController

  http_basic_authenticate_with(
    name: Settings.secure_rooms_api.basic_auth_name,
    password: Settings.secure_rooms_api.basic_auth_password,
  )

  before_action :load_authorizer

  def scan
    @scan_authorizer.perform
    render @scan_authorizer.response
  end

  private

  def load_authorizer
    @scan_authorizer = SecureRooms::ScanAuthorizer.new(
      params[:card_number],
      params[:reader_identifier],
      params[:controller_identifier],
    )
  end

end
