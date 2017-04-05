module SecureRooms

  class ScanResponsePresenter

    def initialize(user, card_reader, access_verdict, accounts)
      @user = user
      @card_reader = card_reader
      @access_verdict = access_verdict
      @accounts = accounts
    end

    def response
      {
        status: status_for_code(@access_verdict.result_code),
        json: {
          tablet_identifier: @card_reader.tablet_token,
          name: @user.full_name,
          response: @access_verdict.result_code,
          reason: @access_verdict.reason,
          accounts: SecureRooms::AccountPresenter.wrap(@accounts),
        },
      }
    end

    private

    def status_for_code(result_code)
      case result_code
      when :grant
        :ok
      when :deny
        :forbidden
      when :pending
        :multiple_choices
      end
    end

  end

end
