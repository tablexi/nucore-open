# frozen_string_literal: true

module SamlAuthentication

  class UserUpdater

    def call(user, saml_response, _auth_value)
      saml_response.attributes.resource_keys.each do |key|
        user.send "#{key}=", saml_response.attribute_value_by_resource_key(key)
      end

      # Once they've signed in with SSO, we don't want to allow them to log in
      # with their password anymore.
      user.encrypted_password = nil
      user.password_salt = nil

      user.save!
    end

  end

end
