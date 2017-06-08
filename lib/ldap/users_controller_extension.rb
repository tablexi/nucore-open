module Ldap

  module UsersControllerExtension

    def service_username_lookup(username)
      Ldap::UserConverter.from_ldap(Ldap::LdapUser.find(username))
    end

  end

end
