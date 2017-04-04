module SecureRooms

  module AccessRules

    class DefaultRestrictionRule < BaseRule

      def evaluate
        deny!("Failed in #{self.class.name}")
      end

    end

  end

end
