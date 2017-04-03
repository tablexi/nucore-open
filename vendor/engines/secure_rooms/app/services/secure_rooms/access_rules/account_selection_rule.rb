module SecureRooms

  module AccessRules

    class AccountSelectionRule < BaseRule

      def self.condition(_user, _card_reader, accounts, selected)
        if selected.present?
          Verdict.new(:grant)
        elsif accounts.present? && selected.blank?
          Verdict.new(:pending, "Must select Account")
        end
      end

    end

  end

end
