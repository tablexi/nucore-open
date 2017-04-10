module SecureRooms

  module AccessRules

    class Verdict

      attr_reader :reason, :user, :card_reader, :result_code, :accounts

      def initialize(result_code, user, card_reader, options = {})
        @result_code = result_code
        @user = user
        @card_reader = card_reader
        @reason = options[:reason]
        @accounts = options[:accounts]
      end

      def pass?
        has_result_code?(:pass)
      end

      def denied?
        has_result_code?(:deny)
      end

      def granted?
        has_result_code?(:grant)
      end

      def has_result_code?(code)
        @result_code == code
      end

    end

  end

end
