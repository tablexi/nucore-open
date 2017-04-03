module SecureRooms

  module AccessRules

    class SelectedAccountRule < BaseRule

      def self.condition(_user, _card_reader, _accounts, selected)
        :ok if selected.present?
      end

    end

  end

end
