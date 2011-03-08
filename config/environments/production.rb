# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true
config.action_view.cache_template_loading            = true

config.action_mailer.raise_delivery_errors = false
config.action_mailer.delivery_method       = :smtp
config.action_mailer.default_url_options   = { :host => "nucore.example.com", :protocol => 'https' }
config.action_mailer.smtp_settings         = {
  :address        => 'mail.example.com',
  :port           => 25,
  :domain         => 'example.com',
}

GOOGLE_ANALYTICS_KEY = nil
RAKE_PATH = '/opt/ruby-enterprise/bin/'