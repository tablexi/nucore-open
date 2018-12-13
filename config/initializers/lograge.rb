# frozen_string_literal: true

unless Rails.env.test? || Rails.env.development?
  Nucore::Application.configure do
    config.lograge.enabled = false
    config.lograge.formatter = Lograge::Formatters::Logstash.new

    # Add params to the log
    config.lograge.custom_options = lambda do |event|
      { params: event.payload[:params].except("controller", "action") }
    end

    # Uncomment to preserve the original Rails logs
    # config.lograge.keep_original_rails_log = true
    # config.lograge.logger = ActiveSupport::Logger.new "#{Rails.root}/log/#{Rails.env}.log.json"
  end
end
