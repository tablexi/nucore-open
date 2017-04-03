module SecureRooms

  module AccessRules

    class Verdict

      attr_accessor :response, :reason

      def initialize(response, reason = nil)
        @response = response
        @reason = reason
      end

      def pass?
        response == :pass
      end

      def ok?
        response == :ok
      end

      def forbidden?
        response == :forbidden
      end

      def multiple_choices?
        response == :multiple_choices
      end

    end

  end

end
