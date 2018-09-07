module SecureRooms

  module AccessRules

    class RequiresUserRule < BaseRule

      def evaluate
        deny!(:user_not_found) if user.nil?
      end

    end

  end

end
