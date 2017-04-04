module SecureRooms

  module AccessRules

    class AccountSelectionRule < BaseRule

      def evaluate
        if @selected.present?
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
