# frozen_string_literal: true

class LogEvent < ApplicationRecord

  belongs_to :user # This is whodunnit
  belongs_to :loggable, polymorphic: true

  scope :reverse_chronological, -> { order(event_time: :desc) }

  # Allows you to LEFT OUTER JOIN a polymorphic table so you can query on it
  # Example: relation.joins_polymorphic(Account)
  # => LEFT OUTER JOINS accounts ON loggable_type = 'Account' AND accounts.id = loggable_id
  scope :joins_polymorphic, ->(clazz) {
    join_table = clazz.arel_table

    join_on = arel_table[:loggable_type].eq(clazz)
      .and(join_table[:id].eq(arel_table[:loggable_id]))
    arel_join = arel_table.join(join_table, Arel::Nodes::OuterJoin).on(join_on)
    joins(arel_join.join_sources)
  }

  def self.log(loggable, event_type, user, event_time: Time.current)
    create(
      loggable: loggable, event_type: event_type,
      event_time: event_time, user_id: user.try(:id))
  end

  def self.search(start_date: nil, end_date: nil, events: [], query: nil)
    LogEventSearcher.new(
      start_date: start_date, end_date: end_date, events: events, query: query).search
  end

  def locale_tag
    "#{loggable_type.underscore.downcase}.#{event_type}"
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
