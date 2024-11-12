# frozen_string_literal: true

module ScheduleRules

  class OpenHours
    attr_reader :schedule_rules

    def initialize(schedule_rules)
      @schedule_rules = schedule_rules
    end

    def self.weekdays
      (0..6).map { |wday| Date::ABBR_DAYNAMES[wday] }
    end

    def per_weekday
      entries = rules_times.group_by { |entry| entry[:weekday] }

      self.class.weekdays.index_with do |weekday|
        entries[weekday]&.pluck(:range)&.join(", ")
      end
    end

    def rules_times
      return @rules_times if @rules_times.present?

      @rules_times =
        self.class.weekdays.flat_map do |weekday|
          wday_rules = schedule_rules.filter { |sr| sr.on_day?(weekday) }

          merged_rule_times(wday_rules).map do |time|
            { weekday:, range: "#{time[:start]} - #{time[:end]}" }
          end
        end
    end

    private

    def merged_rule_times(rules)
      rules.sort_by(&:start_time_int).reduce([[], 0]) do |ac, rule|
        entries, current_time = ac

        if rule.start_time_int == current_time
          entry = entries.last || { start: rule.start_time }
          entry[:end] = rule.end_time
        else
          entries << { start: rule.start_time, end: rule.end_time }
        end

        [entries, rule.end_time_int]
      end.first
    end

  end
end
