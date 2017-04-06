module SecureRooms

  module AccessRules

    class AccountSelectionRule < BaseRule

      def evaluate
        if accounts.blank?
          deny! "User has no valid accounts for this Product"
        elsif selected_account.present?
          grant!
        elsif accounts.present? && accounts.one?
          grant!
        elsif accounts.present? && selected_account.blank?
          pending! "Must select Account"
        end
      end

      private

      def accounts
        params[:accounts]
      end

      def selected_account
        params[:selected_account]
      end

    end

  end

end
