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
        Verdict.new(:pass, @user, @card_reader)
      end

      def grant!(options = {})
        Verdict.new(:grant, @user, @card_reader, options)
      end

      def pending!(options = {})
        Verdict.new(:pending, @user, @card_reader, options)
      end

      def deny!(options = {})
        Verdict.new(:deny, @user, @card_reader, options)
      end

    end

  end

end
