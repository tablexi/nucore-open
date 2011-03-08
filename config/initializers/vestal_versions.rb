VestalVersions.configure do |config|
  # Place any global options here. For example, in order to specify your own version model to use
  # throughout the application, simply specify:
  #
  # config.class_name = "MyCustomVersion"
  #
  # Any options passed to the "versioned" method in the model itself will override this global
  # configuration.
end

require 'vestal_versions'

module VestalVersions
  module Reversion
    module InstanceMethods
      def last_version
        # here's the default implementation using the reserved word 'number' in oracle
        # @last_version ||= versions.maximum(:number) || 1
        @last_version ||= versions.collect(&:number).max || 1
      end
    end
  end
end
