# frozen_string_literal: true

# Be sure to restart your server when you modify this file.
require "nucore"

begin
  if NUCore::Database.oracle?
    ActiveRecord::ConnectionAdapters::OracleEnhancedAdapter.class_eval do
      self.emulate_integers_by_column_name = true
      self.default_sequence_start_value = 1
    end

    # OCI8 does not realize that SafeBuffer is a type of string, so we need to
    # tell it what to do.
    OCI8::BindType::Mapping["ActiveSupport::SafeBuffer"] = OCI8::BindType::String
  end
rescue ActiveRecord::NoDatabaseError
  Rails.logger.warn("This rescue in config/initializers/database.rb is only an acceptable rescue if you are running `rake db:create`")
end
