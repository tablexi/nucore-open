module SecureRooms

  class AccessManager

    attr_reader :verdict

    delegate :user, :card_reader, :reason, :result_code, :accounts, to: :verdict

    def initialize(verdict)
      @verdict = verdict
    end

    def self.process(verdict)
      new(verdict).create_event
    end

    # TODO: Extract and/or update how this fits in once Occupancy is added
    def create_event
      Event.create!(
        occurred_at: Time.current,
        card_reader: card_reader,
        user: user,
        outcome: result_code,
        outcome_details: reason,
      )
    end

  end

end
