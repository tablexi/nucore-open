module SecureRooms

  module AccessRules

    class DefaultRestrictionRule < BaseRule

      def self.condition(_user, _card_reader, _accounts, _selected)
        Verdict.new(:deny, "Failed in #{name}")
      end

    end

  end

end
