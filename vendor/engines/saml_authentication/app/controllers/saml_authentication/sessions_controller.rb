module SamlAuthentication

  class SessionsController < Devise::SamlSessionsController

    protected

    # Remove recall, so failures redirect back to sign_in page
    def auth_options
      { scope: resource_name }
    end

  end

end
