class ScheduleRuleCalendarPresenter

  include ActionView::Helpers::NumberHelper

  attr_reader :schedule_rule, :options

  delegate :end_hour, :end_min, :instrument, :start_hour, :start_min, :unavailable, to: :schedule_rule

  def self.to_json(schedule_rules)
    schedule_rules.flat_map do |schedule_rule|
      new(schedule_rule).to_json
    end
  end

  def initialize(schedule_rule, options = {})
    @schedule_rule = schedule_rule
    @options = options
  end

  def to_json
    Range.new(0, 6).map do |day_index|
      date = (start_date + day_index.days).to_datetime
      hash_for_date(date) if rule_occurs_on_date?(date)
    end.compact
  end

  private

  def hash_for_date(date)
    start_at = date.change(hour: start_hour, min: start_min)
    end_at = date.change(hour: end_hour, min: end_min)

    {
      "className" => class_name,
      "title" => title.to_s,
      "start" => I18n.l(start_at, format: :calendar),
      "end" => I18n.l(end_at, format: :calendar),
      "allDay" => false,
    }
  end

  def class_name
    @class_name ||= unavailable ? "unavailable" : "default"
  end

  def rule_occurs_on_date?(date)
    schedule_rule.public_send("on_#{Date::ABBR_DAYNAMES[date.wday].downcase}?")
  end

  # If start_date is not given, default to the beginning of the current week's Sunday
  def start_date
    options[:start_date].presence || Time.current.beginning_of_week(:sunday).to_date
  end

  def title
    [discount_percent, product_access_groups].compact.join("\n")
  end

  def discount_percent
    if schedule_rule.discount_percent.to_i > 0
      number = number_to_percentage(schedule_rule.discount_percent, strip_insignificant_zeros: true)
      "#{ScheduleRule.human_attribute_name(:discount_percent)}: #{number}"
    end
  end

  def product_access_groups
    if schedule_rule.product_access_groups.any?
      schedule_rule.product_access_groups.join(", ")
    end
  end

end
