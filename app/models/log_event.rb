class LogEvent < ActiveRecord::Base

  belongs_to :user
  belongs_to :loggable, polymorphic: true

end
