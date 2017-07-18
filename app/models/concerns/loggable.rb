module Loggable

  extend ActiveSupport::Concern

  included do
    has_many :log_events, as: :loggable

    after_create :log_create
    after_update :log_update
    after_destroy :log_destroy
  end

  def log_create
    return unless has_attribute?(:created_by)
    LogEvent.create(loggable: self, event_type: :create, user_id: created_by)
  end

  def log_update
    return unless has_attribute?(:updated_by)
    LogEvent.create(loggable: self, event_type: :update, user_id: updated_by)
  end

  def log_destroy
    return unless has_attribute?(:deleted_by)
    LogEvent.create(loggable: self, event_type: :delete, user_id: deleted_by)
  end

end
