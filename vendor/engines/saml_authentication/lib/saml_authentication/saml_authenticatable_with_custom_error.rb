# frozen_string_literal: true

module Devise

  module Models

    SamlAuthenticatableWithCustomError = SamlAuthenticatable

  end

  module Strategies

    class SamlAuthenticatableWithCustomError < SamlAuthenticatable

      private

      # In the original SamlAuthenticatable, this method calls fail!(:invalid), which
      # causes Devise to use the error message defined in devise.failure.invalid. That
      # error message is used by other strategies, including the email and password strategy
      # that we also use, so if we change the message we'll incorrectly affect the other
      # strategies as well. Therefore, we override the method responsible for failing
      # authentication to call fail!(:saml_invalid), which allows us to specify a separate
      # failure message for authentication via SAML.
      def failed_auth(msg)
        DeviseSamlAuthenticatable::Logger.send(msg)
        fail!(I18n.t("devise.failure.saml_invalid").html_safe)
        Devise.saml_failed_callback.new.handle(@response, self) if Devise.saml_failed_callback # rubocop:disable Style/SafeNavigation
      end

    end

  end

end

Warden::Strategies.add(:saml_authenticatable_with_custom_error, Devise::Strategies::SamlAuthenticatableWithCustomError)

Devise.add_module(:saml_authenticatable_with_custom_error,
                  route: :saml_authenticatable,
                  strategy: true,
                  controller: :saml_sessions,
                  model: "devise_saml_authenticatable/model")
