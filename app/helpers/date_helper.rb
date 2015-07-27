module DateHelper

  def usa_formatted_date?(date_string)
    date_string.present? && date_string =~ %r(\A\d{1,2}/\d{1,2}/\d{4}\z)
  end

  def parse_usa_import_date(date_string)
    return nil unless usa_formatted_date?(date_string)
    begin
      parse_mmddyyyy_in_current_zone!(date_string)
    rescue ArgumentError
      nil
    end
  end

  def parse_usa_date(date, extra_date_info=nil)
    begin
      date_string=(date =~ /\d{1,2}\/\d{1,2}\/\d{4}/ ? Date.strptime($&, '%m/%d/%Y') : date).to_s
      date_string += " #{extra_date_info}" if extra_date_info

      Time.zone.parse(date_string)
     rescue
       nil
     end
  end

  def format_usa_date(datetime)
    format_usa_datetime(datetime.try(:to_date))
  end

  def format_usa_datetime(datetime)
    datetime.present? ? I18n.l(datetime, format: :usa) : ''
  end

  def human_date(date)
    "#{Date::MONTHNAMES[date.mon]} #{date.day}, #{date.year}"
  end

  def human_datetime(datetime, args = {})
    return nil if datetime.blank?
    begin
      if args[:date_only]
        format_usa_date(datetime)
      else
        format_usa_datetime(datetime)
      end
    rescue
      ''
    end
  end

  def human_time(dt)
    return nil if dt.nil?
    begin
      dt.strftime("%l:%M %p").strip
    rescue
      ''
    end
  end

  def time_ceil(time, precision = 5.minutes)
    time = time.dup.change(:sec => 0)
    Time.zone.at((time.to_f / precision).ceil * precision)
  end

  def time_floor(time, precision = 5.minutes)
    time = time.dup.change(:sec => 0)
    Time.zone.at((time.to_f / precision).floor * precision)
  end

  def time_select_tag(field, default_time = Time.zone.now)
    output = ""
    output << select_tag("#{field}[hour]", options_for_select(hour_options, default_time.strftime('%I').to_i))
    output << select_tag("#{field}[minute]", options_for_select(minute_options, default_time.min))
    output << select_tag("#{field}[ampm]", options_for_select(['AM', 'PM'], default_time.strftime('%p')))
    output.html_safe
  end

  # This is to DRY up many of the legacy places where hour/min/meridian is used in forms
  def time_select(f, field, options_tag = {}, html_options = {})
    output =  f.select(:"#{field}_hour", (1..12).to_a, {}, html_options)
    output << f.select(:"#{field}_min", minute_options(options_tag[:minute_step]), {}, html_options)
    output << f.select(:"#{field}_meridian", ['AM', 'PM'], {}, html_options)
    content_tag :div, output.html_safe, :class => 'time-select'
  end

  def time_select24(f, field, options = {})
    options.reverse_merge! :hours => (0..23)
    output =  f.select(:"#{field}_hour", options[:hours].to_a)
    output << f.select(:"#{field}_min",minute_options(options[:minute_step]))
    content_tag :div, output, :class => 'time-select'
  end

  def join_time_select_values(values)
    "#{values['hour']}:#{values['minute']} #{values['ampm']}"
  end

  private

  def minute_options(step = nil)
    step ||= 5
    (0..59).step(step).map { |d| ['%02d' % d, d] }
  end

  def hour_options
    (1..12).map {|x| [x,x]}
  end

  def parse_mmddyyyy_in_current_zone!(date_string)
    DateTime.strptime(date_string, '%m/%d/%Y').to_time_in_current_zone
  end
end
