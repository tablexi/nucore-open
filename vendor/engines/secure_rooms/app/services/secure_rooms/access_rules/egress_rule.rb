module SecureRooms

  module AccessRules

    class EgressRule < BaseRule

      def evaluate
        grant! if card_reader.egress?
      end

    end

  end

end
