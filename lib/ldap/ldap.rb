module Ldap
  def self.attribute_field
    # Get the search attribute defined in ldap.yml
    # It might be brittle if they change the internal code, but there
    # is no public API, and this is simpler than reloading the yaml file ourselves
    Devise::LdapAdapter::LdapConnect.new.instance_variable_get :@attribute
  end
end
