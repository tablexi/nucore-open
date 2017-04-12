module SecureRooms

  module AccessRules

    class RequiresApprovalRule < BaseRule

      def evaluate
        deny!(reason: :no_access) unless secure_room.can_be_used_by?(user)
      end

    end

  end

end
