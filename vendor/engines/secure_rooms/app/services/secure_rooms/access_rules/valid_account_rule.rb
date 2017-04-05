module SecureRooms

  module AccessRules

    class ValidAccountRule < BaseRule

      def evaluate
        if @accounts.blank?
          deny! "User has no valid accounts for this Product"
        end
      end

    end

  end

end
