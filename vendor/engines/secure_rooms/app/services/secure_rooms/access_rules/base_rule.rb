module SecureRooms

  module AccessRules

    class BaseRule

      attr_reader :user, :card_reader, :params

      delegate :secure_room, to: :card_reader

      def initialize(user, card_reader, params = {})
        @user = user
        @card_reader = card_reader
        @params = params
        @verdict = Verdict.new(@user, @card_reader)
      end

      def call
        evaluate
        @verdict
      end

      def evaluate
        raise NotImplementedError
      end

      def grant!(reason, options = {})
        @verdict.decide!(:grant, reason, options)
      end

      def pending!(reason, options = {})
        @verdict.decide!(:pending, reason, options)
      end

      def deny!(reason, options = {})
        @verdict.decide!(:deny, reason, options)
      end

    end

  end

end
