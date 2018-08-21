# frozen_string_literal: true

module LdapAuthentication

  module UsersControllerExtension

    def service_username_lookup(username)
      entry = UserEntry.find(username)
      entry.to_user if entry
    end

  end

end
