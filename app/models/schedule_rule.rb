class ScheduleRule < ActiveRecord::Base
  @@durations = [1, 5, 10, 15, 30, 60]
  
  belongs_to :instrument

  attr_accessor :unavailable # virtual attribute

  validates_presence_of :instrument_id
  validates_inclusion_of :duration_mins, :in => @@durations
  validates_numericality_of :discount_percent, :greater_than_or_equal_to => 0, :less_than => 100
  validates_inclusion_of :on_sun, :on_mon, :on_tue, :on_wed, :on_thu, :on_fri, :on_sat, :in => [true, false]
  validates_numericality_of :start_hour, :end_hour, :only_integer => true, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 24
  validates_numericality_of :start_min,  :end_min, :only_integer => true, :greater_than_or_equal_to => 0, :less_than => 60

  validate :at_least_one_day_selected, :end_time_is_after_start_time, :end_time_is_valid, :no_overlap_with_existing_rules, :no_conflict_with_existing_reservation

  def at_least_one_day_selected
    errors.add(:base, "Please select at least one day") unless
      on_sun || on_mon || on_tue || on_wed || on_thu || on_fri || on_sat
  end

  def end_time_is_after_start_time
    return if start_hour.nil? || end_hour.nil? || start_min.nil? || end_min.nil?
    errors.add(:base, "End time must be after start time") if (end_hour < start_hour) || (end_hour == start_hour && end_min <= start_min)
  end

  def end_time_is_valid
    if end_hour == 24 and end_min.to_i != 0
      errors.add(:base, "End time is invalid")
    end
  end

  def no_overlap_with_existing_rules
    return if instrument.blank?
    rules = instrument.schedule_rules.reject {|r| r.id == id} # select all rules except self
    Date::ABBR_DAYNAMES.each do |day|
      # skip unless this rule occurs on this day
      next unless self.send("on_#{day.downcase}")
      # check all existing rules for this day
      rules.select{ |r| r.send("on_#{day.downcase}") }.each do |rule|
        next if self.start_time_int == rule.end_time_int or self.end_time_int == rule.start_time_int # start and end times may touch
        if self.start_time_int.between?(rule.start_time_int, rule.end_time_int) or
           self.end_time_int.between?(rule.start_time_int, rule.end_time_int) or
           (self.start_time_int < rule.start_time_int and self.end_time_int > rule.end_time_int)
          # overlap
          errors.add(:base, "This rule conflicts with an existing rule on #{day}")
        end
      end
    end
  end

  def no_conflict_with_existing_reservation
    # TODO: implement me
    true
  end

  def days_string
    days = []
    Date::ABBR_DAYNAMES.each do |day|
      days << day if self.send("on_#{day.downcase}")
    end
    days.join ', '
  end

  def start_time_int
    start_hour*100+start_min
  end

  def end_time_int
    end_hour*100+end_min
  end

  def start_time
    "#{start_hour}:#{sprintf '%02d', start_min}"
  end

  def end_time
    "#{end_hour}:#{sprintf '%02d', end_min}"
  end 
  
  def self.durations
    @@durations
  end
  
  def includes_datetime(dt)
    dt_int = dt.hour * 100 + dt.min
    self.send("on_#{dt.strftime("%a").downcase}") && dt_int >= start_time_int && dt_int <= end_time_int
  end
  
  # build weekly calendar object
  def as_calendar_object(options={})
    # parse options
    case
    when !options[:start_date].blank?
      start_date = options[:start_date]
    else
      # default
      start_date = :sunday_last
    end

    num_days = options[:num_days] ? options[:num_days].to_i : 7

    case start_date
    when :sunday_last
      # find last sunday
      start_date = self.class.sunday_last
    end

    rules = Range.new(0,num_days-1).inject([]) do |array, i|
      date = start_date + i.days
      # check if rule occurs on this day
      if self.send("on_#{Date::ABBR_DAYNAMES[date.wday].downcase}")
        array << {
          "className" => unavailable ? 'unavailable' : 'default',
          "title"  => unavailable ? '' : "Interval: #{duration_mins.to_s} minute" + (duration_mins == 1 ? '' : 's'),
          "start"  => Time.zone.parse("#{date.year}-#{date.month}-#{date.day} #{start_hour}:#{start_min}").strftime("%a, %d %b %Y %H:%M:%S"),
          "end"    => Time.zone.parse("#{date.year}-#{date.month}-#{date.day} #{end_hour}:#{end_min}").strftime("%a, %d %b %Y %H:%M:%S"),
          "allDay" => false
        }
      end
      array
    end

    rules
  end

  def percent_overlap (start_at, end_at)
    return 0 unless end_at > start_at
    overlap  = 0
    duration = (end_at - start_at)/60
    # TODO rewrite to be more efficient; don't iterate over every minute
    while (start_at < end_at)
      if start_at.hour*100+start_at.min >= start_time_int && start_at.hour*100+start_at.min < end_time_int && self.send("on_#{start_at.strftime("%a").downcase}?")  
        overlap += 1
      end
      start_at += 60
    end
    overlap / duration
  end

  def self.unavailable(rules, options={})
    # rules is always a collection
    rules     = Array(rules)
    not_rules = []

    # group rules by day, sort by start_hour
    Date::ABBR_DAYNAMES.each do |day|
      day_rules = rules.select{ |rule| rule.send("on_#{day.downcase}") }.sort_by{ |rule| rule.start_hour }
      # for now, skip days with no rules
      if day_rules.empty?
        # build entire day not rule
        not_rule = ScheduleRule.new("on_#{day.downcase}" => true, :start_hour => 0, :start_min => 0, :end_hour => 24, :end_min => 0,
                                    :unavailable => true)
        not_rule.freeze
        not_rules.push(not_rule)
        next
      end
      # build not available rules as contiguous blocks between existing rules
      not_start_hour = 0
      not_start_min  = 0
      day_rules.each do |day_rule|
        if day_rule.start_hour == not_start_hour and day_rule.start_min == not_start_min
          # adjust not times, but don't build a not rule
          not_start_hour  = day_rule.end_hour
          not_start_min   = day_rule.end_min
          next
        end
        not_rule = ScheduleRule.new("on_#{day.downcase}" => true, :unavailable => true)
        not_rule.start_hour = not_start_hour
        not_rule.start_min  = not_start_min
        not_rule.end_hour   = day_rule.start_hour
        not_rule.end_min    = day_rule.start_min
        not_start_hour      = day_rule.end_hour
        not_start_min       = day_rule.end_min
        not_rule.freeze
        not_rules.push(not_rule)
      end
      unless not_start_hour == 24 and not_start_min == 0
        # build not rule for last part of day
        not_rule = ScheduleRule.new("on_#{day.downcase}" => true, :unavailable => true)
        not_rule.start_hour = not_start_hour
        not_rule.start_min  = not_start_min
        not_rule.end_hour   = 24
        not_rule.end_min    = 0
        not_rule.freeze
        not_rules.push(not_rule)
      end
    end
    
    not_rules
  end

  def self.sunday_last
    today = Time.zone.now
    (today - today.wday.days).to_date
  end

end
