Nucore::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.perform_deliveries = true
  Rails.application.routes.default_url_options =
    config.action_mailer.default_url_options = { host: "localhost", port: 3000 }

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Do not compress assets
  config.assets.compress = false

  # Do not log assets path
  config.assets.quiet = true

  # Expands the lines which load the assets
  config.assets.debug = true

  config.assets.raise_runtime_errors = true

  # Raise exceptions when missing I18n translations
  config.action_view.raise_on_missing_translations = true

  config.after_initialize do
    Bullet.enable = false
    Bullet.bullet_logger = true
    Bullet.rails_logger = true
  end
end

# What's this for?
GOOGLE_ANALYTICS_KEY = nil
RAKE_PATH = nil
