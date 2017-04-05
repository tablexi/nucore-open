module SecureRooms

  module AccessRules

    class ValidAccountRule < BaseRule

      def evaluate
        deny! "User has no valid accounts for this Product" if @accounts.blank?
      end

    end

  end

end
