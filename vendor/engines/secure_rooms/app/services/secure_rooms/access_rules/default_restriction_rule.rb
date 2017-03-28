module SecureRooms

  module AccessRules

    class DefaultRestrictionRule

      def self.call(_user, _card_reader, _accounts, _selected)
        :forbidden
      end

    end

  end

end
