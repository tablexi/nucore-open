class CalendarObjectBuilder

  attr_reader :options, :schedule_rule

  delegate :end_hour, :end_min, :instrument, :start_hour, :start_min, :unavailable, to: :schedule_rule

  def initialize(schedule_rule, options = {})
    @schedule_rule = schedule_rule
    @options = options
  end

  def generate
    Range.new(0, num_days - 1).each_with_object([]) do |day_index, array|
      date = (start_date + day_index.days).to_datetime
      array << hash_for_date(date) if rule_occurs_on_date?(date)
    end
  end

  private

  def hash_for_date(date)
    start_at = date.change(hour: start_hour, min: start_min)
    end_at = date.change(hour: end_hour, min: end_min)

    {
      "className" => class_name,
      "title" => title,
      "start" => I18n.l(start_at, format: :calendar),
      "end" => I18n.l(end_at, format: :calendar),
      "allDay" => false,
    }
  end

  def class_name
    @class_name ||= unavailable ? "unavailable" : "default"
  end

  def num_days
    options[:num_days] ? options[:num_days].to_i : 7
  end

  def rule_occurs_on_date?(date)
    schedule_rule.public_send("on_#{Date::ABBR_DAYNAMES[date.wday].downcase}?")
  end

  def start_date
    options[:start_date].presence || schedule_rule.class.sunday_last
  end

  def title
    @title ||=
      if instrument && !unavailable
        duration_mins = instrument.reserve_interval
        "Interval: #{duration_mins} minute#{duration_mins == 1 ? '' : 's'}"
      else
        ""
      end
  end

end
