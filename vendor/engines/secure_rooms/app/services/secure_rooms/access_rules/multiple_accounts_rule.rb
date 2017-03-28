module SecureRooms

  module AccessRules

    class MultipleAccountsRule

      def self.call(_user, _card_reader, accounts, selected)
        return :multiple_choices if accounts.present? && selected.blank?
      end

    end

  end

end
