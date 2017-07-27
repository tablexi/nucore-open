class LogEventSearcher

  ALLOWED_EVENTS = ["account.create", "account.update",
                    "account_user.create", "account_user.delete",
                    "user.create"].freeze

  attr_accessor :start_date, :end_date, :events, :query

  def initialize(start_date: nil, end_date: nil, events: [], query: nil)
    @start_date = start_date
    @end_date = end_date
    @events = filter_events(events)
    @query = query
  end

  def filter_events(events)
    Array(events).select { |event| event.in?(ALLOWED_EVENTS) }
  end

  def search
    result = LogEvent.all
    result = result.merge(filter_date) if start_date || end_date
    result = result.merge(filter_event) if events.present?
    result = result.merge(filter_query) if query.present?
    result
  end

  def dates
    [(start_date || LogEvent.minimum(:event_time)), (end_date || Date.current)]
  end

  def filter_date
    LogEvent.where(event_time: (dates.min.beginning_of_day..dates.max.end_of_day))
  end

  # When this gets updated to Rails 5, you can use ActiveRecord#or directly
  # the event name comes in as <loggable_type>.<event_type>
  def filter_event
    where_strings = events.flatten.map do |event|
      loggable_type, event_type = event.split(".")
      "(`loggable_type` = '#{loggable_type.camelize}' AND `event_type` = '#{event_type}')"
    end
    LogEvent.where(where_strings.join(" OR "))
  end

  def filter_query
    accounts = Account.where("account_number LIKE ?", "%#{query}%")
    users = UserFinder.search(query, 1000)[0]
    where_string = [
      filter_loggable_string("Account", accounts),
      filter_loggable_string("User", users),
    ].compact.join(" OR ")
    LogEvent.where(where_string)
  end

  def filter_loggable_string(loggable_type, loggable_objects)
    return nil if loggable_objects.empty?
    id_string = loggable_objects.map(&:id).join(",")
    "(`loggable_type` ='#{loggable_type}' AND `loggable_id` IN (#{id_string}))"
  end

end
