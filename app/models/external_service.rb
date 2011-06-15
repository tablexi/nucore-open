#
# Represents a 3rd party service in use by the system
class ExternalService < ActiveRecord::Base
  validates_presence_of :location
end
