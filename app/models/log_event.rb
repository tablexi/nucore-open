# frozen_string_literal: true

class LogEvent < ApplicationRecord

  belongs_to :user # This is whodunnit
  belongs_to :loggable, -> { with_deleted if respond_to?(:with_deleted) }, polymorphic: true
  serialize :metadata, JSON
  scope :reverse_chronological, -> { order(event_time: :desc) }

  def self.log(loggable, event_type, user, event_time: Time.current, metadata: nil)
    create(
      loggable: loggable, event_type: event_type,
      event_time: event_time, user_id: user.try(:id),
      metadata: metadata)
  end

  def self.search(start_date: nil, end_date: nil, events: [], query: nil)
    LogEventSearcher.new(
      start_date: start_date, end_date: end_date, events: events, query: query).search
  end

# The reason that we are doing this is because in some case we can't add a default value to a text column
  def metadata
    self[:metadata] || {}
  end

  def facility
    if loggable.respond_to?(:facility)
      loggable.facility
    elsif loggable.respond_to?(:price_group_with_deleted)
      loggable.price_group_with_deleted.facility
    elsif loggable.respond_to?(:facilities)
      loggable.facilities.first if loggable.facilities.count == 1
    elsif loggable.respond_to?(:user)
      loggable.user.facilities.first if loggable.user.facilities.count == 1
    end
  end

  def locale_tag
    "#{loggable_type.underscore.downcase}.#{event_type}"
  end

  def loggable_to_s
    if loggable.respond_to?(:to_log_s)
      loggable.to_log_s
    else
      loggable.to_s
    end
  end

end
