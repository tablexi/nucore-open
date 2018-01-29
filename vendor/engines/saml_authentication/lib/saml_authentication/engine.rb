require "devise_saml_authenticatable"
require "saml_authentication/routes"
require "saml_authentication/model"

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

      Devise.setup do |config|
        idp_metadata_parser = OneLogin::RubySaml::IdpMetadataParser.new
        config.saml_config = idp_metadata_parser.parse_remote(Settings.saml.idp_metadata)

        config.saml_configure do |settings|
          settings.assertion_consumer_service_url = Rails.application.routes.url_helpers.auth_saml_user_session_url
          settings.issuer = Rails.application.routes.url_helpers.metadata_saml_user_session_url

          config.saml_session_index_key = :session_index
          config.saml_use_subject = true
          config.saml_create_user = false
          config.saml_update_user = false # TODO: Fix me
          config.saml_default_user_key = :email # TODO change to :username
          config.saml_resource_locator
        end
      end
    end

  end

end
