# frozen_string_literal: true

module SamlAuthentication

  class UserLocator

    def call(model, saml_response, _auth_value)
      username = saml_response.attribute_value_by_resource_key(:username)
      email = saml_response.attribute_value_by_resource_key(:email)

      model.find_by(username: username) || model.find_by(email: email)
    end

  end

end
