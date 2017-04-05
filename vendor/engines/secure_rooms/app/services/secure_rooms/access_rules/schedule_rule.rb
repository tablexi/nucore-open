module SecureRooms

  module AccessRules

    class ScheduleRule < BaseRule

      def evaluate
        deny!("No schedule rules configured") if secure_room.schedule_rules.none?
        deny!("Outside of schedule rules") unless secure_room.schedule_rules.cover?(Time.current)
      end

    end

  end

end
