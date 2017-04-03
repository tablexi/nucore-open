module SecureRooms

  module AccessRules

    class Verdict

      attr_accessor :reason

      def initialize(result_code, reason = nil)
        @result_code = result_code
        @reason = reason
      end

      def http_status
        @http_status ||= status_for_code(@result_code)
      end

      def pass?
        @result_code == :pass
      end

      def has_result_code?(code)
        @result_code == code
      end

      private

      def status_for_code(result_code)
        case result_code
        when :grant
          :ok
        when :deny
          :forbidden
        when :pending
          :multiple_choices
        end
      end

    end

  end

end
