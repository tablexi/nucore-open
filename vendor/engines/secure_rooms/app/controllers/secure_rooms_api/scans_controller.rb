class SecureRoomsApi::ScansController < ApplicationController

  http_basic_authenticate_with(
    name: Settings.secure_rooms_api.basic_auth_name,
    password: Settings.secure_rooms_api.basic_auth_password,
  )

  before_action :load_user_and_reader

  def scan
    accounts = @user.accounts_for_product(@card_reader.secure_room)
    selected_account = accounts.find { |account| account.id == params[:account_identifier] }

    access_result = SecureRooms::CheckAccess.new.authorize(
      @user,
      @card_reader,
      accounts,
      selected_account,
    )

    render json: build_json(accounts), status: access_result.response
  end

  private

  def build_json(accounts)
    {
      # TODO: (#140895375) return actual tablet_identifier
      tablet_identifier: "abc123",
      name: @user.full_name,
      accounts: SecureRooms::AccountPresenter.wrap(accounts),
    }
  end

  def load_user_and_reader
    @user = User.find_by!(card_number: params[:card_number])
    @card_reader = SecureRooms::CardReader.find_by!(
      card_reader_number: params[:reader_identifier],
      control_device_number: params[:controller_identifier],
    )
  end

end
