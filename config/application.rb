require File.expand_path("../boot", __FILE__)
require "rails/all"
require "will_paginate/array"

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(assets: %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module Nucore

  class Application < Rails::Application

    # TODO: This disables strong parameters across the board:
    config.action_controller.permit_all_parameters = false

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += Dir["#{config.root}/lib/**/"]
    config.autoload_paths += Dir["#{config.root}/app/models/**/"]
    config.autoload_paths += Dir["#{config.root}/app/controllers/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/mailers/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/models/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/validators"]

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    config.active_record.observers = :order_detail_observer
    #:cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # TODO: Rails 4 can move this into an initializer meaning we can move it into
    # settings.yml or secrets.yml
    config.time_zone = "Central Time (US & Canada)"

    # The default locale is :en and all translations under config/locales/ are auto-loaded
    # But we want to make sure anything in the override folder happens at the very end
    initializer "nucore.i18n.move_overrides_to_end", after: "text_helpers.i18n.add_load_paths" do
      config.i18n.load_path -= Dir[Rails.root.join("config", "locales", "override", "*.{rb,yml}").to_s]
      config.i18n.load_path += Dir[Rails.root.join("config", "locales", "override", "*.{rb,yml}").to_s]
    end
    # config.i18n.default_locale = :de

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = "1.0"

    config.assets.initialize_on_precompile = false

    # Configure our frameworks of choice
    config.generators do |g|
      g.template_engine :haml
      g.test_framework :rspec
    end

    config.active_record.raise_in_transactional_callbacks = true

    config.active_job.queue_adapter = :delayed_job

  end

end
