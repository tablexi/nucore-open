module Ldap

  module UsersControllerExtension

    def service_username_lookup(username)
      Ldap::LdapUser.find(username)
    end

  end

end
