module SecureRooms

  module AccessRules

    class ScheduleRule < BaseRule

      def evaluate
        deny!(reason: "No schedule rules configured") if secure_room.schedule_rules.none?
        deny!(reason: "Outside of schedule rules") unless secure_room.schedule_rules.cover?(Time.current)
        deny!(reason: "User not in schedule group") unless secure_room.available_schedule_rules(user).cover?(Time.current)
      end

    end

  end

end
