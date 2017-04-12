module SecureRooms

  module AccessRules

    class ArchivedProductRule < BaseRule

      def evaluate
        deny!(reason: :archived) if secure_room.is_archived?
      end

    end

  end

end
