module SecureRooms

  module AccessRules

    class OperatorRule < BaseRule

      def self.condition(user, card_reader, _accounts, _selected)
        :ok if user.operator_of?(card_reader.facility)
      end

    end

  end

end
