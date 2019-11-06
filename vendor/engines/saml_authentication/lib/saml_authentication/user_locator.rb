# frozen_string_literal: true

require "saml_authentication/saml_attributes"

module SamlAuthentication

  class UserLocator

    def call(model, saml_response, _auth_value)
      attributes = SamlAttributes.new(saml_response)
      Rails.logger.debug("[SAML] Parsed attributes: #{attributes.to_h}")
      Rails.logger.debug("[SAML] Raw attributes: #{attributes.to_raw_h}")

      username = attributes[:username]
      email = attributes[:email]

      model.find_by(username: username) || model.find_by(email: email)
    end

  end

end
