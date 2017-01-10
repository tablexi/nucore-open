# Load the rails application
require File.expand_path("../application", __FILE__)

# TODO: RAILS5
# Versions of the Oracle adapter before 1.7 make an assumption that a Time value
# without fractional seconds is actually a Date. This causes failures most
# consistently in tests, because time helpers always sets usec to zero, but
# could also happen in the wild 1 out of 1000 times.
#
# Remove this require and patch file after upgrading the gem to 1.7 or above,
# which only supports Rails 5.0 and up.
if Rails.version < "5.0"
  if defined?(ActiveRecord::ConnectionAdapters::OracleEnhancedAdapter)
    require File.expand_path("../../lib/patches/oracle_enhanced_adapter", __FILE__)
  end
else
  raise "Remove the reference to the oracle_enhanced_adapter patch in #{__FILE__} for Rails 5+"
end

# Initialize the rails application
Nucore::Application.initialize!
