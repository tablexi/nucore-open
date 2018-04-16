module SamlAuthentication

  class SessionsController < Devise::SamlSessionsController

    after_action :store_winning_strategy, only: :create

    protected

    # Remove recall, so failures redirect back to sign_in page
    def auth_options
      { scope: resource_name }
    end

    # This will be used to choose which Logout link is shown to the user.
    # https://github.com/apokalipto/devise_saml_authenticatable/wiki/Supporting-multiple-authentication-strategies
    def store_winning_strategy
      warden.session(resource_name)[:strategy] = warden.winning_strategies[resource_name].class.name.demodulize.underscore.to_sym
    end

  end

end
