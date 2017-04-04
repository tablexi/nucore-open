module SecureRooms

  module AccessRules

    class BaseRule

      def initialize(user, card_reader, accounts, selected)
        @user = user
        @card_reader = card_reader
        @accounts = accounts
        @selected = selected
      end

      def call
        evaluate || pass
      end

      def evaluate(_user, _card_reader, _accounts, _selected)
        raise NotImplementedError
      end

      def pass
        Verdict.new(:pass)
      end

      def grant!
        Verdict.new(:grant)
      end

      def pending!(reason)
        Verdict.new(:pending, reason: reason)
      end

      def deny!(reason)
        Verdict.new(:deny, reason: reason)
      end

    end

  end

end
