module SecureRooms

  class ScanResponsePresenter

    def initialize(user, access_verdict, accounts)
      @user = user
      @access_verdict = access_verdict
      @accounts = accounts
    end

    def response
      {
        status: status_for_code(@access_verdict.result_code),
        json: {
          # TODO: (#140895375) return actual tablet_identifier
          tablet_identifier: "abc123",
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
