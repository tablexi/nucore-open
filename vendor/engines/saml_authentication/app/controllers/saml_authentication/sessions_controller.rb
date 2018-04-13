module SamlAuthentication

  class SessionsController < Devise::SamlSessionsController

    # Some SSO providers are strict and require that the name_identifier matches
    # what's logged in on their system for SLO.
    before_action(only: :destroy) { @signed_out_username = current_user.public_send(Devise.saml_default_user_key) }

    protected

    # Remove recall, so failures redirect back to sign_in page
    def auth_options
      { scope: resource_name }
    end

    def after_sign_out_path_for(_)
      idp_entity_id = get_idp_entity_id(params)
      request = OneLogin::RubySaml::Logoutrequest.new
      config = saml_config(idp_entity_id).dup
      config.name_identifier_value = @signed_out_username
      request.create(config)
    end

  end

end
