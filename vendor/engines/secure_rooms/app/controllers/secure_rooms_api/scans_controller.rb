class SecureRoomsApi::ScansController < ApplicationController

  http_basic_authenticate_with(
    name: Settings.secure_rooms_api.basic_auth_name,
    password: Settings.secure_rooms_api.basic_auth_password,
  )

  before_action :load_user_and_reader

  def scan
    requested_id = params[:account_identifier].to_i

    access_manager = SecureRooms::AccessManager.new(@user, @card_reader, requested_id)
    access_manager.process

    render SecureRooms::ScanResponsePresenter.new(
      @user,
      @card_reader,
      access_manager.verdict,
      access_manager.accounts,
    ).response
  end

  private

  def load_user_and_reader
    @user = User.find_by!(card_number: params[:card_number])
    @card_reader = SecureRooms::CardReader.find_by!(
      card_reader_number: params[:reader_identifier],
      control_device_number: params[:controller_identifier],
    )
  end

end
