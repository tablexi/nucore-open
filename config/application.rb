require File.expand_path('../boot', __FILE__)

require 'rails/all'
require File.join(File.dirname(__FILE__), '..', 'vendor', 'engines', 'nucs', 'lib', 'engine')

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module Nucore
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(#{config.root}/lib #{config.root}/app/middleware #{config.root}/config)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Configure our frameworks of choice
    config.generators do |g|
     g.template_engine :haml
     g.test_framework :rspec
    end
  end
end

require File.dirname(__FILE__) + "/Constants.rb"

# This is what makes the nucore extension system work.
# See doc/README.extensions for details on nucore extensions.
Dir["#{Rails.root}/lib/extensions/*.rb"].each do |file|
  require file
  file_name=File.basename(file, File.extname(file))
  next unless file_name.ends_with?('_extension')
  base_name=file_name[0...file_name.rindex('_')]
  base=base_name.camelize.constantize

  base.class_eval %Q<
    def initialize(*args)
      super(*args)
      after_find
    end

    def after_find
      extend #{file_name.camelize}
    end
  >
end
