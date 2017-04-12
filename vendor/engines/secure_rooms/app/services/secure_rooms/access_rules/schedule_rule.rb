module SecureRooms

  module AccessRules

    class ScheduleRule < BaseRule

      def evaluate
        deny!(reason: :no_rules) if secure_room.schedule_rules.none?
        deny!(reason: :outside_rules) unless secure_room.schedule_rules.cover?(Time.current)
        deny!(reason: :not_in_group) unless secure_room.available_schedule_rules(user).cover?(Time.current)
      end

    end

  end

end
