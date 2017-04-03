module SecureRooms

  module AccessRules

    class MultipleAccountsRule < BaseRule

      def self.condition(_user, _card_reader, accounts, selected)
        :multiple_choices if accounts.present? && selected.blank?
      end

    end

  end

end
