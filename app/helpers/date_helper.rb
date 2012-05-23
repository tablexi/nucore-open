module DateHelper

  def parse_usa_date(date, extra_date_info=nil)
    date_string=(date =~ /\d{1,2}\/\d{1,2}\/\d{4}/ ? Date.strptime(date, '%m/%d/%Y') : date).to_s
    date_string += " #{extra_date_info}" if extra_date_info

    begin Time.zone.parse(date_string) rescue nil end
  end

  def human_date(date)
    "#{Date::MONTHNAMES[date.mon]} #{date.day}, #{date.year}"
  end

  def human_datetime(dt, args = {})
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
    begin
      dt.strftime("%l:%M %p")
    rescue
      ''
    end
  end

end
