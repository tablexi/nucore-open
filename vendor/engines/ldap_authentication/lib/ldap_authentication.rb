require "devise_ldap_authenticatable"
require "ldap_authentication/user_entry"
require "ldap_authentication/user_converter"
require "ldap_authentication/engine"

module LdapAuthentication

  mattr_accessor :config

  def self.attribute_field
    config["attribute"]
  end

end
