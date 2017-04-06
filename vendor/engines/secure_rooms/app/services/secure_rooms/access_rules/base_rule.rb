module SecureRooms

  module AccessRules

    class BaseRule

      attr_reader :user, :card_reader, :params

      delegate :secure_room, to: :card_reader

      def initialize(user, card_reader, params = {})
        @user = user
        @card_reader = card_reader
        @params = params
      end

      def call
        evaluate || pass
      end

      def evaluate
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
