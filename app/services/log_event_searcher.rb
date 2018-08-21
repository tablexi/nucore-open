# frozen_string_literal: true

class LogEventSearcher

  ALLOWED_EVENTS = ["account.create", "account.update",
                    "account_user.create", "account_user.delete",
                    "user.create"].freeze

  def self.beginning_of_time
    10.years.ago
  end

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
    [(start_date || LogEventSearcher.beginning_of_time), (end_date || Date.current)]
  end

  def filter_date
    LogEvent.where(event_time: (dates.min.beginning_of_day..dates.max.end_of_day))
  end

  # When this gets updated to Rails 5, you can use ActiveRecord#or directly
  # Also, the event name comes in as <loggable_type>.<event_type>
  def filter_event
    where_strings = events.flatten.map do |event|
      loggable_type, event_type = event.split(".")
      "(loggable_type = '#{loggable_type.camelize}' AND event_type = '#{event_type}')"
    end
    LogEvent.where(where_strings.join(" OR "))
  end

  # Some of these queryies become easier to write in Rails 5 when
  #  you can use ActiveRecord#or directly
  def filter_query
    account_ids = Account.where("account_number LIKE ?", "%#{query}%").pluck(:id)
    user_ids = UserFinder.search(query, nil)[0].map(&:id)
    account_user_ids = AccountUser.where(account_id: account_ids).pluck(:id) +
                       AccountUser.where(user_id: user_ids).pluck(:id)
    account_logs = LogEvent.where(
      loggable_type: "Account", loggable_id: account_ids).pluck(:id)
    user_logs =  LogEvent.where(
      loggable_type: "User", loggable_id: user_ids).pluck(:id)
    account_user_logs = LogEvent.where(
      loggable_type: "AccountUser", loggable_id: account_user_ids).pluck(:id)
    LogEvent.where(id: account_logs + user_logs + account_user_logs)
  end

end
