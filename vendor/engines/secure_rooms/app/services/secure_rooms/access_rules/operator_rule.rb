module SecureRooms

  module AccessRules

    class OperatorRule < BaseRule

      def evaluate
        grant!(:operator, skip_order: true) if user.operator_of?(card_reader.facility)
      end

    end

  end

end
