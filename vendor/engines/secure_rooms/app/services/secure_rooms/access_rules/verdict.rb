module SecureRooms

  module AccessRules

    class Verdict

      attr_accessor :status, :reason

      def initialize(status, reason = nil)
        @status = status
        @reason = reason
      end

      def pass?
        status == :pass
      end

      def has_status?(status_symbol)
        status == status_symbol
      end

    end

  end

end
