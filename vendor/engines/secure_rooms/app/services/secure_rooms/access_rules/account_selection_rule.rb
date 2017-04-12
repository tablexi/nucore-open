module SecureRooms

  module AccessRules

    class AccountSelectionRule < BaseRule

      def evaluate
        accounts = user.accounts_for_product(card_reader.secure_room)
        selected_account = accounts.find { |account| account.id == requested_account_id }

        if accounts.blank?
          deny!(reason: :no_accounts)
        elsif selected_account.present?
          grant!(accounts: accounts)
        elsif accounts.present? && accounts.one?
          grant!(accounts: accounts)
        elsif accounts.present? && selected_account.blank?
          pending!(reason: :selection_needed, accounts: accounts)
        end
      end

      private

      def requested_account_id
        params[:requested_account_id].to_i
      end

    end

  end

end
