module SamlAuthentication

  class SessionsController < Devise::SamlSessionsController

    # Some SSO providers are strict and require that the name_identifier matches
    # what's logged in on their system for SLO.
    before_action :store_logging_out_username, only: :destroy
    after_action :store_winning_strategy, only: :create

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

    private

    def store_logging_out_username
      @signed_out_username = current_user.public_send(Devise.saml_default_user_key)
    end

    # This will be used to choose which Logout link is shown to the user.
    # https://github.com/apokalipto/devise_saml_authenticatable/wiki/Supporting-multiple-authentication-strategies
    def store_winning_strategy
      warden.session(resource_name)[:strategy] = warden.winning_strategies[resource_name].class.name.demodulize.underscore.to_sym
    end

  end

end
