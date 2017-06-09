module Ldap

  module UsersControllerExtension

    def service_username_lookup(username)
      entry = Ldap::UserEntry.find(username)
      entry.to_user if entry
    end

  end

end
