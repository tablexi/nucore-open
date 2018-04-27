require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Nucore
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # The default locale is :en and all translations under config/locales/ are auto-loaded
    # But we want to make sure anything in the override folder happens at the very end
    initializer "nucore.i18n.move_overrides_to_end", after: "text_helpers.i18n.add_load_paths" do
      config.i18n.load_path -= Dir[Rails.root.join("config", "locales", "override", "*.{rb,yml}").to_s]
      config.i18n.load_path += Dir[Rails.root.join("config", "locales", "override", "*.{rb,yml}").to_s]
    end

    config.active_job.queue_adapter = :delayed_job

    config.time_zone = "Central Time (US & Canada)" # move to settings

  end
end
