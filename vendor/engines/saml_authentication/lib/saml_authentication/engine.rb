require "devise_saml_authenticatable"
require "saml_authentication/routes"
require "saml_authentication/model"
require "saml_authentication/devise_configurator"

module SamlAuthentication

  class Engine < Rails::Engine

    config.to_prepare do
      User.send(:devise, :saml_authenticatable)
      ViewHook.add_hook "devise.sessions.new",
                        "before_login_form",
                        "saml_authentication/sessions/new"
    end

    config.after_initialize do
      Rails.application.reload_routes!

      SamlAuthentication::DeviseConfigurator.new.configure!
    end

  end

end
