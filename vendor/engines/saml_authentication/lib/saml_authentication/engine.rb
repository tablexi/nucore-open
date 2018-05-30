require "devise_saml_authenticatable"
require "saml_authentication/routes"
require "saml_authentication/model"
require "saml_authentication/devise_configurator"

module SamlAuthentication

  class Engine < Rails::Engine

    config.to_prepare do
      next if Settings.saml.blank?

      User.send(:devise, :saml_authenticatable)
      if Settings.saml.login_enabled
        ViewHook.add_hook "devise.sessions.new",
                          "before_login_form",
                          "saml_authentication/sessions/new"
      end

      OneLogin::RubySaml::Logging.logger.level = Rails.env.production? ? Logger::INFO : Logger::DEBUG
    end

    config.after_initialize do
      next if Settings.saml.blank?

      Rails.application.reload_routes!

      SamlAuthentication::DeviseConfigurator.new.configure!
    end

  end

end
