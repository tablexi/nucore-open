module Ldap
  module UsersControllerExtension
    def new_search
      super
    end

    def username_search
      super
    end

    def username_lookup(username)
      Ldap::Search.new.search(username).first
    end
  end
end
