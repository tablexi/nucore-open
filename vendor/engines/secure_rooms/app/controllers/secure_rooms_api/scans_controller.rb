class SecureRoomsApi::ScansController < ApplicationController

  http_basic_authenticate_with(
    name: Settings.secure_rooms_api.basic_auth_name,
    password: Settings.secure_rooms_api.basic_auth_password,
  )

  before_action :load_user_and_reader

  def scan
    accounts = @user.accounts_for_product(@card_reader.secure_room)
    requested_id = params[:account_identifier].to_i
    selected_account = accounts.find { |account| account.id == requested_id }

    access_verdict = SecureRooms::CheckAccess.new.authorize(
      @user,
      @card_reader,
      accounts: accounts,
      selected_account: selected_account,
    )

    render SecureRooms::ScanResponsePresenter.new(@user, @card_reader, access_verdict, accounts).response
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
