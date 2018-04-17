module SamlAuthentication

  # The default IdpEntityIdReader triggers an error on SLO because that request to
  # us has a SAMLResponse parameter, which does not get parsed by OneLogin::RubySaml::Response
  # correctly: "Issuer of the Response not found or multiple."
  # Overrides DeviseSamlAuthenticatable::DefaultIdpEntityIdReader.
  class IdpEntityIdReader

    def self.entity_id(params)
      if params[:action] == "idp_sign_out" && params[:SAMLResponse]
        OneLogin::RubySaml::Logoutresponse.new(
          params[:SAMLResponse],
          settings: Devise.saml_config,
          allowed_clock_drift: Devise.allowed_clock_drift_in_seconds,
        ).issuer
      else
        original_implementation(params)
      end
    end

    # Copied rather than inherited from default class for clarity.
    def self.original_implementation(params)
      if params[:SAMLRequest]
        OneLogin::RubySaml::SloLogoutrequest.new(
          params[:SAMLRequest],
          settings: Devise.saml_config,
          allowed_clock_drift: Devise.allowed_clock_drift_in_seconds,
        ).issuer
      elsif params[:SAMLResponse]
        OneLogin::RubySaml::Response.new(
          params[:SAMLResponse],
          settings: Devise.saml_config,
          allowed_clock_drift: Devise.allowed_clock_drift_in_seconds,
        ).issuers.first
      end
    end

  end

end
