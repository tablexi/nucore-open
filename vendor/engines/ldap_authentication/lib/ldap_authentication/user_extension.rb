module LdapAuthentication

  module UserExtension

    extend ActiveSupport::Concern

    class_methods do
      # Overrides default from devise_ldap_authenticatable
      def find_for_ldap_authentication(attributes = {})
        resource = super
        resource unless resource.authenticated_locally?
      end
    end

    # Overrides the default no-op from devise_ldap_authenticatable
    def after_ldap_authentication
      entry = UserEntry.find(username)
      # Something has gone horribly wrong if the user is not found here.
      raise "User #{username} not found in LDAP after authentication." unless entry

      update_attributes!(UserConverter.new(entry).attributes)
    rescue ActiveRecord::RecordInvalid => e
      # If the record is invalid (e.g. a duplicate email address), trigger an email
      # notification, but let the user through. Their information will not be updated.
      ActiveSupport::Notifications.instrument(
        "background_error",
        exception: e,
        information: "Could not update User #{username} because of validation errors"
      )
    end

  end

end
