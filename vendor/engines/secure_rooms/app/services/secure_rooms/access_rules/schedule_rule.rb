# frozen_string_literal: true

module SecureRooms

  module AccessRules

    class ScheduleRule < BaseRule

      def evaluate
        deny!(:no_schedule) if secure_room.schedule_rules.none?
        deny!(:outside_schedule) unless secure_room.schedule_rules.cover?(Time.current)
        deny!(:not_in_group) unless secure_room.available_schedule_rules(user).cover?(Time.current)
        deny!(:holiday_access_restricted) unless card_reader.egress? || Holiday.allow_access?(user, secure_room, Time.current)
      end

    end

  end

end
