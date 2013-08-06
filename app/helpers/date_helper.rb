module DateHelper

  def parse_usa_date(date, extra_date_info=nil)
    begin
      date_string=(date =~ /\d{1,2}\/\d{1,2}\/\d{4}/ ? Date.strptime($&, '%m/%d/%Y') : date).to_s
      date_string += " #{extra_date_info}" if extra_date_info

      Time.zone.parse(date_string)
     rescue
       nil
     end
  end

  def format_usa_date(date)
    date.strftime("%m/%d/%Y")
  end

  def human_date(date)
    "#{Date::MONTHNAMES[date.mon]} #{date.day}, #{date.year}"
  end

  def human_date_with_day(date)
    date.strftime("%A, %B %e, %Y")
  end

  def human_datetime(dt, args = {})
    return nil if dt.nil?
    begin
      if args[:date_only]
        dt.strftime("%m/%d/%Y")
      else
        dt.strftime("%m/%d/%Y %l:%M %p")
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

  def time_select_tag(field, default_time = Time.zone.now)
    output = ""
    output << select_tag("#{field}[hour]", options_for_select(hour_options, default_time.strftime('%I').to_i))
    output << select_tag("#{field}[minute]", options_for_select(minute_options, default_time.min))
    output << select_tag("#{field}[ampm]", options_for_select(['AM', 'PM'], default_time.strftime('%p')))
    output.html_safe
  end

  # This is to DRY up many of the legacy places where hour/min/meridian is used in forms
  def time_select(f, field)
    output =  f.select(:"#{field}_hour", (1..12).to_a)
    output << f.select(:"#{field}_min", minute_options)
    output << f.select(:"#{field}_meridian", ['AM', 'PM'])
    content_tag :div, output.html_safe, :class => 'time-select'
  end

  def time_select24(f, field, options = {})
    options.reverse_merge! :hours => (0..23)
    output =  f.select(:"#{field}_hour", options[:hours].to_a)
    output << f.select(:"#{field}_min",minute_options)
    content_tag :div, output, :class => 'time-select'
  end

  def join_time_select_values(values)
    "#{values['hour']}:#{values['minute']} #{values['ampm']}"
  end

  private

  def minute_options(step = 5)
    (0..59).step(step).map { |d| ['%02d' % d, d] }
  end

  def hour_options
    (1..12).map {|x| [x,x]}
  end
end
