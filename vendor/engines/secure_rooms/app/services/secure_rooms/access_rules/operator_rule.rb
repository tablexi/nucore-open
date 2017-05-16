module SecureRooms

  module AccessRules

    class OperatorRule < BaseRule

      def evaluate
        grant!(:operator) if user.operator_of?(card_reader.facility, allow_global: false)
      end

    end

  end

end
