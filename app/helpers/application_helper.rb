# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def app_name
    NUCore.app_name
  end

  def html_title(title=nil)
    full_title = title.nil? ? "" : "#{title} - "
    full_title += app_name
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
  
  def human_rate_calculation(rate, subsidy)
    # handle nil input
    rate    = 0 if rate.nil?
    subsidy = 0 if subsidy.nil?
    
    # render appropriate string
    if subsidy > 0
      "#{number_to_currency rate}<br />-#{number_to_currency subsidy}<br /> =<b>#{number_to_currency rate-subsidy}</b>"
    elsif rate > 0
      number_to_currency rate
    else
      ""
    end
  end
  
  def sortable (column, title = nil)
    title ||= column.titleize
    direction = column == sort_column && sort_direction == 'asc' ? 'desc' : 'asc'
    link_to title, {:sort => column, :dir => direction}, {:class => (column == sort_column ? sort_direction : 'sortable')}
  end
end
