class SecureRoomsApi::ScansController < ApplicationController

  http_basic_authenticate_with(
    name: Settings.secure_rooms_api.basic_auth_name,
    password: Settings.secure_rooms_api.basic_auth_password,
  )

  rescue_from ActiveRecord::RecordNotFound, with: :report_missing_ids

  before_action :load_models

  def scan
    user_accounts = @user.accounts_for_product(@card_reader.secure_room)

    if user_accounts.present?
      response_status = user_accounts.many? ? :multiple_choices : :ok

      # TODO: needs a legitimage tablet_identifier once tablet exists
      response_json = {
        response: "select_account",
        tablet_identifier: "abc123",
        name: @user.full_name,
        accounts: SecureRooms::AccountPresenter.wrap(user_accounts),
      }
    else
      response_status = :forbidden
      response_json = {
        response: "deny",
        reason: "No accounts found",
      }
    end

    render json: response_json, status: response_status
  end

  def load_models
    @user = User.find_by!(card_number: params[:card_number])
    @card_reader = SecureRooms::CardReader.find_by!(
      card_reader_number: params[:reader_identifier],
      control_device_number: params[:controller_identifier],
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
