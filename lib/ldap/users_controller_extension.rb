module Ldap
  module UsersControllerExtension
    def service_username_lookup(username)
      Ldap::Search.new.search(username).first
    end
  end
end
