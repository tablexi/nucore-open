module SecureRooms

  class ScanResponsePresenter

    def initialize(verdict)
      @verdict = verdict
    end

    attr_reader :verdict

    delegate :user, :card_reader, :reason, :accounts, to: :verdict

    def response
      {
        status: status_for_code(verdict.result_code),
        json: {
          tablet_identifier: card_reader.tablet_token,
          name: user.full_name,
          response: verdict.result_code,
          reason: verdict.reason,
          accounts: SecureRooms::AccountPresenter.wrap(accounts),
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
