module SecureRooms

  module AccessRules

    class DenyAllRule < BaseRule

      def evaluate
        deny!(reason: :rules_failed)
      end

    end

  end

end
