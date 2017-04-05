module SecureRooms

  module AccessRules

    class AccountSelectionRule < BaseRule

      def evaluate
        if @accounts.blank?
          deny! "User has no valid accounts for this Product"
        elsif @selected.present?
          grant!
        elsif @accounts.present? && @accounts.one?
          grant!
        elsif @accounts.present? && @selected.blank?
          pending! "Must select Account"
        end
      end

    end

  end

end
