module SecureRooms

  module AccessRules

    class Verdict

      attr_accessor :reason, :result_code

      def initialize(result_code, reason = nil)
        @result_code = result_code
        @reason = reason
      end

      def pass?
        @result_code == :pass
      end

      def has_result_code?(code)
        @result_code == code
      end

    end

  end

end
