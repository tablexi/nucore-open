module SecureRooms

  module AccessRules

    class DefaultRestrictionRule < BaseRule

      def self.condition(_user, _card_reader, _accounts, _selected)
        :forbidden
      end

    end

  end

end
