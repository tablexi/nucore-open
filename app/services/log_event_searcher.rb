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

  def filter_query
    relation = LogEvent.joins_polymorphic(Account)
      .joins_polymorphic(User)
      .joins_polymorphic(AccountUser)
      .joins("LEFT OUTER JOIN accounts AS account_user_accounts ON account_users.account_id = account_user_accounts.id")
      .joins("LEFT OUTER JOIN users AS account_user_users ON account_users.user_id = account_user_users.id")

    [
      Account.where("accounts.account_number LIKE ?", "%#{query}%"),
      Account.where("account_user_accounts.account_number LIKE ?", "%#{query}%"),
      UserFinder.search(query).unscope(:order),
      UserFinder.search(query, table_alias: "account_user_users").unscope(:order),
    ].map { |filter| relation.merge(filter) }.inject(&:or)
  end

end
