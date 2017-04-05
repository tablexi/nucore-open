module SecureRooms

  module AccessRules

    class ArchivedProductRule < BaseRule

      def evaluate
        deny! "Product is archived" if @card_reader.secure_room.is_archived?
      end

    end

  end

end
