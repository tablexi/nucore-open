module SecureRooms

  module AccessRules

    class OperatorRule

      def self.call(user, card_reader, _accounts, _selected)
        return :ok if user.operator_of?(card_reader.facility)
      end

    end

  end

end
