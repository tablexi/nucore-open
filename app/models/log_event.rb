class LogEvent < ActiveRecord::Base

  belongs_to :user
  belongs_to :loggable, polymorphic: true

  def self.log(loggable, event_type, user)
    create(loggable: loggable, event_type: event_type, user_id: user.id)
  end

end
