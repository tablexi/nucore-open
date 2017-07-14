module Loggable

  extend ActiveSupport::Concern

  included do
    has_many :log_events, as: :loggable

    after_create :log_create
    after_update :log_update
  end

  def log_create
    LogEvent.create(loggable: self, event_type: :create, user_id: created_by)
  end

  def log_update
    LogEvent.create(loggable: self, event_type: :update, user_id: updated_by)
  end

end
