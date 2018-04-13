require "devise_saml_authenticatable"
require "saml_authentication/routes"
require "saml_authentication/model"
require "saml_authentication/devise_configurator"

module SamlAuthentication

  class Engine < Rails::Engine

    config.to_prepare do
      next if Settings.saml.blank?

      User.send(:devise, :saml_authenticatable)
      ViewHook.add_hook "devise.sessions.new",
                        "before_login_form",
                        "saml_authentication/sessions/new"

      OneLogin::RubySaml::Logging.logger.level = Logger::DEBUG
    end

    config.after_initialize do
      next if Settings.saml.blank?

      Rails.application.reload_routes!

      SamlAuthentication::DeviseConfigurator.new.configure!
    end

    initializer :append_migrations do |app|
      config.paths["db/migrate"].expanded.each do |expanded_path|
        app.config.paths["db/migrate"] << expanded_path
      end
    end

  end

end
