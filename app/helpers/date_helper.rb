module DateHelper

  def parse_usa_date(date, extra_date_info=nil)
    date_string=(date =~ /\d{1,2}\/\d{1,2}\/\d{4}/ ? Date.strptime(date, '%m/%d/%Y') : date).to_s
    date_string += " #{extra_date_info}" if extra_date_info

    begin Time.zone.parse(date_string) rescue nil end
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

  def human_date_extra_info(date)
    result = ""
    result << "Today, " if date.beginning_of_day == Time.zone.now.beginning_of_day
    result << "Tomorrow, " if date.beginning_of_day == (Time.zone.now.beginning_of_day + 1.day)
    result << "Yesterday, " if date.beginning_of_day == (Time.zone.now.beginning_of_day - 1.day)
    result << human_date_with_day(date)
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

end
