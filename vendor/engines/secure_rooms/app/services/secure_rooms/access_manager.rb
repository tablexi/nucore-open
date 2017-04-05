module SecureRooms

  class AccessManager

    attr_reader :verdict

    def initialize(user, card_reader, requested_account_id)
      @user = user
      @card_reader = card_reader
      @requested_account_id = requested_account_id
    end

    def process
      @verdict = create_verdict
      event = create_event(verdict)
    end

    # TODO: Extract
    def create_verdict
      SecureRooms::CheckAccess.new.authorize(
        @user,
        @card_reader,
        accounts: accounts,
        selected_account: selected_account,
      )
    end

    # TODO: Extract
    def create_event(verdict)
      Event.create!(
        occurred_at: Time.current,
        card_reader: @card_reader,
        user: @user,
        outcome: verdict,
      )
    end

    def accounts
      @accounts ||= @user.accounts_for_product(@card_reader.secure_room)
    end

    def selected_account
      @selected_account ||= accounts.find { |account| account.id == @requested_account_id }
    end

  end

end
