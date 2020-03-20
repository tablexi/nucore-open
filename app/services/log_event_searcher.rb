# frozen_string_literal: true

class LogEventSearcher

  ALLOWED_EVENTS = ["account.create", "account.update",
                    "account_user.create", "account_user.delete",
                    "user.create", "statement.create"].freeze

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

  # The event name comes in as <loggable_type>.<event_type>
  def filter_event
    events.flatten.map do |event|
      loggable_type, event_type = event.split(".")
      LogEvent.where(loggable_type: loggable_type.camelize, event_type: event_type)
    end.inject(&:or)
  end

  def filter_query
    accounts = Account.where(Account.arel_table[:account_number].lower.matches("%#{query.downcase}%"))
    users = UserFinder.search(query).unscope(:order)
    account_users = AccountUser.where(account_id: accounts).or(AccountUser.where(user_id: users))

    [
      accounts,
      users,
      account_users,
    ].map do |filter|
      LogEvent.where(loggable_type: filter.model.name, loggable_id: filter)
    end.inject(&:or)
  end

end
