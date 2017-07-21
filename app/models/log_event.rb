class LogEvent < ActiveRecord::Base

  belongs_to :user
  belongs_to :loggable, polymorphic: true

  def self.log(loggable, event_type, event_time, user)
    create(
      loggable: loggable, event_type: event_type,
      event_time: event_time, user_id: user.try(:id))
  end

  def self.search(start_date: nil, end_date: nil, events: [])
    result = all
    result = result.filter_date(start_date, end_date) if start_date || end_date
    result = result.filter_event(events) if events.present?
    result
  end

  def self.filter_date(start_date, end_date)
    dates = [(start_date || 10.years.ago), (end_date || Date.current)]
    where(event_time: (dates.min..dates.max))
  end

  # When this gets updated to Rails 5, you can use ActiveRecord#or directly
  def self.filter_event(*events)
    where_strings = events.flatten.map do |event|
      loggable_type, event_type = event.split("__")
      "(`loggable_type` = '#{loggable_type.camelize}' AND `event_type` = '#{event_type}')"
    end
    where(where_strings.join(" OR "))
  end

  def locale_tag
    "#{loggable_type.underscore.downcase}__#{event_type}"
  end

  def loggable_to_s
    case loggable
    when AccountUser
      "#{loggable.account} / #{loggable.user}"
    else
      loggable.to_s
    end
  end

end
