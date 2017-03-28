module SecureRooms

  module AccessRules

    class SelectedAccountRule

      def self.call(_user, _card_reader, _accounts, selected)
        return :ok if selected.present?
      end

    end

  end

end
