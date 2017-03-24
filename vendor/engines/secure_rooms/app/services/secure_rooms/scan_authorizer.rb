module SecureRooms

  class ScanAuthorizer

    include TextHelpers::Translation

    def initialize(card_number, reader_identifier, controller_identifier)
      @user = User.find_by(card_number: card_number)
      @card_reader = SecureRooms::CardReader.find_by(
        card_reader_number: reader_identifier,
        control_device_number: controller_identifier,
      )
    end

    def perform
      if error_reasons.present?
        set_error_response
      elsif denial_reasons.present?
        set_denial_response
      else
        set_accounts_response
      end
    end

    def response
      @response ||= { json: @response_json, status: @response_status }
    end

    def user_accounts
      @user_accounts ||= @user.accounts_for_product(@card_reader.secure_room)
    end

    def set_accounts_response
      @response_status = user_accounts.many? ? :multiple_choices : :ok
      @response_json = {
        response: "select_account",
        # TODO: needs a legitimage tablet_identifier once tablet exists
        tablet_identifier: "abc123",
        name: @user.full_name,
        accounts: SecureRooms::AccountPresenter.wrap(user_accounts),
      }
    end

    def set_error_response
      @response_status = :not_found
      @response_json = {
        response: "deny",
        reason: error_reasons,
      }
    end

    def set_denial_response
      @response_status = :forbidden
      @response_json = {
        response: "deny",
        reason: denial_reasons,
      }
    end

    def denial_reasons
      [].tap do |reasons|
        reasons << text("errors.no_accounts") if user_accounts.empty?
        # TODO: Validate what other denial logic is valid
        # reasons << "wrong facility somehow" if user.facility_does_not_match?
        # reasons << "not on access list somehow" if user.not_on_access_list?
        # reasons << "archived room somehow" if room.archived?
      end.to_sentence
    end

    def error_reasons
      [].tap do |reasons|
        reasons << text("errors.card_not_found") if @user.blank?
        reasons << text("errors.reader_not_found") if @card_reader.blank?
      end.to_sentence
    end

    protected

    def translation_scope
      "services.secure_rooms/scan_authorizer"
    end

  end

end
