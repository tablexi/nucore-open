module Ldap
  class Search
    def search(query)
      return [] unless query
      escaped_query = Net::LDAP::Filter.escape(query)
      ldap_users = admin_ldap.search(:base => admin_ldap.base, :filter => "#{Ldap.attribute_field}=#{escaped_query}")
      ldap_users.map { |u| make_user_from_ldap(u) }
    end

    private

    def admin_ldap
      Devise::LdapAdapter::LdapConnect.admin
    end

    def make_user_from_ldap(ldap_user)
      Ldap::UserConverter.new(ldap_user).user
    end
  end
end
