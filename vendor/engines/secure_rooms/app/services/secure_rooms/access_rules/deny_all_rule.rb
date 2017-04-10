module SecureRooms

  module AccessRules

    class DenyAllRule < BaseRule

      def evaluate
        deny!(reason: "Failed in #{self.class.name}")
      end

    end

  end

end
