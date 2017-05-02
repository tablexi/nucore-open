module SecureRooms

  module AccessHandlers

    class EventHandler

      def self.process(verdict)
        Event.create!(
          occurred_at: Time.current,
          card_reader: verdict.card_reader,
          user: verdict.user,
          account: verdict.selected_account,
          skip_order: verdict.skip_order,
          outcome: verdict.result_code,
          outcome_details: verdict.reason,
        )
      end

    end

  end

end
