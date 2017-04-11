module SecureRooms

  class AccessManager

    def self.process(verdict)
      create_event(verdict)
    end

    # TODO: Extract
    def self.create_event(verdict)
      Event.create!(
        occurred_at: Time.current,
        card_reader: verdict.card_reader,
        user: verdict.user,
        # TODO: store a useful way of tracking the outcome
        outcome: verdict,
      )
    end

  end

end
